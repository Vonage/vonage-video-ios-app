//
//  Created by Vonage on 26/2/26.
//

import CoreImage
import CoreMedia
import CoreVideo
import Foundation
import OpenTok
import ReplayKit
import VERAScreenShare

/// Feeds borrowed ReplayKit frames synchronously into the SDK using one owned output buffer.
/// Control callbacks never wait for rendering or hold a lock while invoking SDK consumers.
/// A busy renderer drops an overlapping frame instead of creating a queue of work.
// Sendability is confined to this adapter: controlLock protects all control state, and
// conversionLock owns frame storage. Raw SDK frames, consumers and sample buffers are
// never enqueued or declared Sendable. The in-flight group joins deliveries after closure.
final class ScreenShareVideoCapturer: NSObject, OTVideoCapture, @unchecked Sendable {
    private let controlLock = NSLock()
    private let conversionLock = NSLock()
    private let inFlight = DispatchGroup()
    private let retransmitQueue = DispatchQueue(label: "com.vonage.VERA.screenshare.retransmit")
    private let retransmitInterval: DispatchTimeInterval
    private let settings: ScreenShareVideoSettings
    private let minimumFrameSpacing: DispatchTimeInterval

    // Protected by controlLock.
    private var storedVideoContentHint: OTVideoContentHint = .detail
    private var storedVideoCaptureConsumer: OTVideoCaptureConsumer?
    private var capturing = false
    private var isSessionReady = false
    private var paused = false
    private var closed = false
    private var captureCycle: UInt64 = 0
    private var timerGeneration: UInt64 = 0
    private var retransmitTimer: DispatchSourceTimer?

    // Protected by conversionLock. SDK consumer calls happen only while owning this
    // non-recursive lease; reentrant or overlapping frame callbacks fail try() and drop.
    fileprivate var videoFrame = OTVideoFrame(format: OTVideoFormat(argbWithWidth: 0, height: 0))
    fileprivate var pixelBuffer: CVPixelBuffer?
    fileprivate var lastSampleBuffer: CMSampleBuffer?
    fileprivate let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var lastOrientation: OTVideoOrientation = .up
    private var lastFrameTimestamp: CMTime?
    private var timestampCycle: UInt64 = 0
    private var lastDeliveryTime: TimeInterval?
    private var deliveryCycle: UInt64 = 0

    private static let duplicateThresholdSeconds = 0.002

    init(
        settings: ScreenShareVideoSettings = .init(),
        retransmitInterval: DispatchTimeInterval = .milliseconds(250)
    ) {
        self.settings = settings
        self.retransmitInterval = retransmitInterval
        minimumFrameSpacing = .milliseconds(Int(ceil(settings.minimumFrameInterval * 1000)))
        super.init()
    }

    deinit {
        retransmitTimer?.cancel()
    }

    var videoContentHint: OTVideoContentHint {
        get { controlLock.withLock { storedVideoContentHint } }
        set { controlLock.withLock { storedVideoContentHint = newValue } }
    }

    var videoCaptureConsumer: OTVideoCaptureConsumer? {
        get { controlLock.withLock { storedVideoCaptureConsumer } }
        set {
            let previous = controlLock.withLock {
                let previous = storedVideoCaptureConsumer
                storedVideoCaptureConsumer = newValue
                return previous
            }
            // Releasing the final SDK reference can itself execute external cleanup.
            withExtendedLifetime(previous) {}
        }
    }

    var isClosed: Bool { controlLock.withLock { closed } }
    var isPaused: Bool { controlLock.withLock { paused } }

    /// Identifies the currently scheduled static-frame delivery. Expired tickets are ignored.
    var retransmissionGeneration: UInt64 { controlLock.withLock { timerGeneration } }

    func setPaused(_ paused: Bool) {
        controlLock.withLock {
            guard !closed else { return }
            self.paused = paused
            if paused { invalidateTimerLocked() }
        }
    }

    /// Closes admission immediately; an already reserved SDK delivery may still be finishing.
    func close() {
        let didClose = controlLock.withLock {
            guard !closed else { return false }
            closed = true
            capturing = false
            isSessionReady = false
            invalidateTimerLocked()
            return true
        }
        if didClose {
            inFlight.notify(queue: retransmitQueue) { [weak self] in
                self?.releaseFrameStorage()
            }
        }
    }

    /// Runs completion only after existing synchronous consumer calls have returned.
    /// Notification never blocks the caller, including when invoked reentrantly by the SDK.
    func close(on queue: DispatchQueue, completion: @escaping @Sendable () -> Void) {
        close()
        inFlight.notify(queue: queue, execute: completion)
    }

    /// Forms UI cleanup on its owner before the nonisolated drain notification retains it.
    @MainActor
    func closeOnMainActor(completion: @escaping @MainActor @Sendable () -> Void) {
        close(on: .main) {
            MainActor.assumeIsolated { completion() }
        }
    }

    func sessionDidConnect() {
        controlLock.withLock {
            guard !closed else { return }
            isSessionReady = true
        }
    }

    func sessionDidDisconnect() {
        controlLock.withLock {
            isSessionReady = false
            captureCycle &+= 1
            invalidateTimerLocked()
        }
    }

    // MARK: - OTVideoCapture

    func initCapture() {}

    func releaseCapture() {
        close()
        videoCaptureConsumer = nil
    }

    func start() -> Int32 {
        controlLock.withLock {
            guard !closed else { return -1 }
            if !capturing { captureCycle &+= 1 }
            capturing = true
            return 0
        }
    }

    func stop() -> Int32 {
        controlLock.withLock {
            capturing = false
            captureCycle &+= 1
            invalidateTimerLocked()
            return 0
        }
    }

    func isCaptureStarted() -> Bool {
        controlLock.withLock { capturing }
    }

    func captureSettings(_ videoFormat: OTVideoFormat) -> Int32 {
        videoFormat.pixelFormat = .ARGB
        if let fps = settings.frameRate { videoFormat.estimatedFramesPerSecond = Double(fps) }
        return 0
    }

    // MARK: - Synchronous frame leases

    private struct Delivery {
        let consumer: OTVideoCaptureConsumer
        let generation: UInt64
        let cycle: UInt64
    }

    // Called only while holding conversionLock. Admission and DispatchGroup.enter happen
    // under the same control lock as close, so finish cannot miss an admitted delivery.
    private func reserveDelivery(
        expectedGeneration: UInt64? = nil,
        timestamp: CMTime? = nil
    ) -> Delivery? {
        controlLock.withLock {
            guard capturing, isSessionReady, !paused, !closed,
                let consumer = storedVideoCaptureConsumer
            else { return nil }
            if let expectedGeneration, expectedGeneration != timerGeneration { return nil }
            if let timestamp, timestampCycle == captureCycle, let previous = lastFrameTimestamp {
                let delta = CMTimeGetSeconds(CMTimeSubtract(timestamp, previous))
                if abs(delta) < Self.duplicateThresholdSeconds { return nil }
            }
            invalidateTimerLocked()
            inFlight.enter()
            return Delivery(consumer: consumer, generation: timerGeneration, cycle: captureCycle)
        }
    }

    private func finishDelivery(_ delivery: Delivery) {
        if lastSampleBuffer != nil, pixelBuffer != nil {
            scheduleRetransmission(expectedGeneration: delivery.generation)
        }
        conversionLock.unlock()
        inFlight.leave()
    }

    func consumeVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard conversionLock.try() else { return }
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard let delivery = reserveDelivery(timestamp: pts) else {
            conversionLock.unlock()
            return
        }
        defer { finishDelivery(delivery) }
        guard !isWithinMinimumFrameInterval(of: delivery) else { return }
        guard let source = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        lastFrameTimestamp = pts
        timestampCycle = delivery.cycle
        let image = CIImage(cvPixelBuffer: source)
        let extent = image.extent
        checkSize(width: Int(extent.width), height: Int(extent.height))
        guard let output = pixelBuffer else { return }

        CVPixelBufferLockBaseAddress(output, [])
        defer { CVPixelBufferUnlockBaseAddress(output, []) }
        let width = CVPixelBufferGetWidth(output)
        let height = CVPixelBufferGetHeight(output)
        let scaled = image.transformed(
            by: CGAffineTransform(scaleX: CGFloat(width) / extent.width, y: CGFloat(height) / extent.height))
        ciContext.render(scaled, to: output, bounds: scaled.extent, colorSpace: CGColorSpaceCreateDeviceRGB())

        lastOrientation = sampleOrientation(from: sampleBuffer).otOrientation
        videoFrame.timestamp = pts
        videoFrame.format?.estimatedCaptureDelay = 100
        videoFrame.orientation = lastOrientation
        let planes = NSPointerArray(options: .opaqueMemory)
        planes.addPointer(CVPixelBufferGetBaseAddress(output))
        videoFrame.planes = planes
        lastSampleBuffer = sampleBuffer

        // Neither SDK code nor consumer callbacks execute under controlLock. The output
        // buffer and borrowed input remain alive for this synchronous call.
        delivery.consumer.consumeFrame(videoFrame)
        recordDelivery(delivery)
    }

    // Called only while holding conversionLock. A new capture cycle starts unthrottled.
    private func isWithinMinimumFrameInterval(of delivery: Delivery) -> Bool {
        guard deliveryCycle == delivery.cycle, let lastDeliveryTime else { return false }
        return ProcessInfo.processInfo.systemUptime - lastDeliveryTime < settings.minimumFrameInterval
    }

    private func recordDelivery(_ delivery: Delivery) {
        lastDeliveryTime = ProcessInfo.processInfo.systemUptime
        deliveryCycle = delivery.cycle
    }

    private func sampleOrientation(from sampleBuffer: CMSampleBuffer) -> CGImagePropertyOrientation {
        guard
            let value = CMGetAttachment(
                sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil),
            let rawValue = (value as? NSNumber)?.uint32Value
        else { return .up }
        return CGImagePropertyOrientation(rawValue: rawValue) ?? .up
    }

    // MARK: - Static-frame retransmission

    // Called only while holding controlLock; no external callbacks run here.
    private func invalidateTimerLocked() {
        timerGeneration &+= 1
        retransmitTimer?.cancel()
        retransmitTimer = nil
    }

    private func scheduleRetransmission(expectedGeneration: UInt64) {
        controlLock.withLock {
            guard capturing, isSessionReady, !paused, !closed, timerGeneration == expectedGeneration else { return }
            invalidateTimerLocked()
            let generation = timerGeneration
            let timer = DispatchSource.makeTimerSource(flags: .strict, queue: retransmitQueue)
            // Static frames never repeat faster than the configured frame rate.
            let now = DispatchTime.now()
            timer.schedule(
                deadline: max(now + retransmitInterval, now + minimumFrameSpacing), leeway: .milliseconds(20))
            timer.setEventHandler { [weak self] in
                self?.retransmitLastFrame(expectedGeneration: generation)
            }
            timer.activate()
            retransmitTimer = timer
        }
    }

    /// A queued timer can outlive cancellation. Its generation must still own the frame.
    func retransmitLastFrame(expectedGeneration: UInt64) {
        guard conversionLock.try() else { return }
        guard let delivery = reserveDelivery(expectedGeneration: expectedGeneration) else {
            conversionLock.unlock()
            return
        }
        defer { finishDelivery(delivery) }
        guard let output = pixelBuffer else { return }
        CVPixelBufferLockBaseAddress(output, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(output, .readOnly) }
        videoFrame.timestamp = CMClockGetTime(CMClockGetHostTimeClock())
        videoFrame.format?.estimatedCaptureDelay = 100
        videoFrame.orientation = lastOrientation
        let planes = NSPointerArray(options: .opaqueMemory)
        planes.addPointer(CVPixelBufferGetBaseAddress(output))
        videoFrame.planes = planes
        delivery.consumer.consumeFrame(videoFrame)
        recordDelivery(delivery)
    }

    private func releaseFrameStorage() {
        conversionLock.lock()
        defer { conversionLock.unlock() }
        lastSampleBuffer = nil
        pixelBuffer = nil
    }
}

extension CGImagePropertyOrientation {
    var otOrientation: OTVideoOrientation {
        switch self {
        case .up, .upMirrored: .up
        case .down, .downMirrored: .down
        case .left, .leftMirrored: .left
        case .right, .rightMirrored: .right
        }
    }
}

// MARK: - Buffer management

extension ScreenShareVideoCapturer {
    /// Returns output dimensions within the independent screen-sharing bounds.
    fileprivate func outputSize(for inputWidth: Int, _ inputHeight: Int) -> (width: Int, height: Int) {
        settings.outputDimensions(width: inputWidth, height: inputHeight)
    }

    fileprivate func checkSize(width srcWidth: Int, height srcHeight: Int) {
        let (width, height) = outputSize(for: srcWidth, srcHeight)

        let currentFormat = videoFrame.format
        guard
            currentFormat == nil
                || currentFormat!.imageWidth != UInt32(width)
                || currentFormat!.imageHeight != UInt32(height)
        else { return }

        // Recreate OTVideoFrame with a fresh format — mutating the existing format
        // in-place is unreliable because OTVideoFrame caches internal state at init time.
        let newFormat = OTVideoFormat(argbWithWidth: UInt32(width), height: UInt32(height))
        if let fps = settings.frameRate { newFormat.estimatedFramesPerSecond = Double(fps) }
        newFormat.bytesPerRow.removeAllObjects()
        newFormat.bytesPerRow.addObjects(from: [width * 4])
        videoFrame = OTVideoFrame(format: newFormat)

        var newBuffer: CVPixelBuffer?
        // Use BGRA — the SDK reads BGRA bytes when told pixelFormat = .ARGB on iOS.
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: false,
                kCVPixelBufferCGBitmapContextCompatibilityKey: false,
            ] as CFDictionary,
            &newBuffer
        )
        assert(status == kCVReturnSuccess && newBuffer != nil)
        pixelBuffer = newBuffer
    }
}
