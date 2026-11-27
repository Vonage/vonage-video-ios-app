//
//  Created by Vonage on 19/11/26.
//

import CoreImage
import CoreMedia
import CoreVideo
import Foundation
import OpenTok
import VERAScreenShare
import os

/// Feeds ScreenCaptureKit frames into the Vonage SDK through one owned BGRA buffer.
///
/// The incoming sample buffer is borrowed for the duration of `consumeVideoSampleBuffer`
/// and is not stored. A busy renderer drops an overlapping frame. Sendable state lives in
/// `OSAllocatedUnfairLock`. Pixel storage and the SDK consumer stay on this object and are
/// touched by one frame at a time.
final class InProcessScreenShareCapturer: NSObject, OTVideoCapture, @unchecked Sendable {
    private struct Control: Sendable {
        var videoContentHint: OTVideoContentHint = .text
        var capturing = false
        var isSessionReady = false
        var paused = false
        var closed = false
        var captureCycle: UInt64 = 0
        var timerGeneration: UInt64 = 0
        var lastFrameTimestamp: CMTime?
        var timestampCycle: UInt64 = 0
    }

    private let control = OSAllocatedUnfairLock(initialState: Control())
    private let frameLease = OSAllocatedUnfairLock(initialState: false)
    private let inFlight = DispatchGroup()
    private let retransmitQueue = DispatchQueue(label: "com.vonage.VERA.screenshare.retransmit")
    private let retransmitInterval: DispatchTimeInterval
    private static let duplicateThresholdSeconds = 0.002

    nonisolated(unsafe) private var storedConsumer: OTVideoCaptureConsumer?
    nonisolated(unsafe) private var videoFrame = OTVideoFrame(format: OTVideoFormat(argbWithWidth: 0, height: 0))
    nonisolated(unsafe) private var pixelBuffer: CVPixelBuffer?
    nonisolated(unsafe) private var retransmitTimer: DispatchSourceTimer?
    nonisolated(unsafe) private var lastOrientation: OTVideoOrientation = .up
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    init(retransmitInterval: DispatchTimeInterval = .milliseconds(250)) {
        self.retransmitInterval = retransmitInterval
        super.init()
    }

    deinit {
        retransmitTimer?.cancel()
    }

    var videoContentHint: OTVideoContentHint {
        get { control.withLock { $0.videoContentHint } }
        set { control.withLock { $0.videoContentHint = newValue } }
    }

    var videoCaptureConsumer: OTVideoCaptureConsumer? {
        get { control.withLockUnchecked { _ in storedConsumer } }
        set { control.withLockUnchecked { _ in storedConsumer = newValue } }
    }

    func sessionDidConnect() {
        control.withLock { state in
            guard !state.closed else { return }
            state.isSessionReady = true
        }
    }

    func sessionDidDisconnect() {
        control.withLock { state in
            state.isSessionReady = false
            state.captureCycle &+= 1
            invalidateTimer(&state)
        }
    }

    func close() {
        let didClose = control.withLock { state -> Bool in
            guard !state.closed else { return false }
            state.closed = true
            state.capturing = false
            state.isSessionReady = false
            invalidateTimer(&state)
            return true
        }
        guard didClose else { return }
        // Keep `self` until an in-flight frame returns. Waiting here can deadlock when the
        // caller is on the main queue and the SDK frame callback needs that queue.
        inFlight.notify(queue: retransmitQueue) { [self] in
            guard self.beginFrame() else { return }
            self.pixelBuffer = nil
            self.endFrame()
        }
    }

    func initCapture() {
        // ScreenCaptureKit owns the frames. The SDK calls this hook and there is nothing to allocate.
    }

    func releaseCapture() {
        close()
        videoCaptureConsumer = nil
    }

    func start() -> Int32 {
        control.withLock { state in
            guard !state.closed else { return -1 }
            if !state.capturing { state.captureCycle &+= 1 }
            state.capturing = true
            return 0
        }
    }

    func stop() -> Int32 {
        control.withLock { state in
            state.capturing = false
            state.captureCycle &+= 1
            invalidateTimer(&state)
            return 0
        }
    }

    func isCaptureStarted() -> Bool {
        control.withLock { $0.capturing }
    }

    func captureSettings(_ videoFormat: OTVideoFormat) -> Int32 {
        videoFormat.pixelFormat = .ARGB
        return 0
    }

    func consumeVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard beginFrame() else { return }
        defer { endFrame() }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard let generation = reserveDelivery(timestamp: timestamp) else { return }
        defer { inFlight.leave() }
        guard let source = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: source)
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return }
        prepareBuffer(width: Int(extent.width), height: Int(extent.height))
        guard let output = pixelBuffer else { return }

        CVPixelBufferLockBaseAddress(output, [])
        defer { CVPixelBufferUnlockBaseAddress(output, []) }
        let width = CVPixelBufferGetWidth(output)
        let height = CVPixelBufferGetHeight(output)
        let scaled = image.transformed(
            by: CGAffineTransform(
                scaleX: CGFloat(width) / extent.width,
                y: CGFloat(height) / extent.height))
        ciContext.render(
            scaled,
            to: output,
            bounds: scaled.extent,
            colorSpace: CGColorSpaceCreateDeviceRGB())
        control.withLock { state in
            state.lastFrameTimestamp = timestamp
            state.timestampCycle = state.captureCycle
        }
        lastOrientation = .up
        deliver(output, timestamp: timestamp, orientation: .up)
        scheduleRetransmission(expectedGeneration: generation)
    }

    func retransmitLastFrame(expectedGeneration: UInt64) {
        guard beginFrame() else { return }
        defer { endFrame() }
        guard let generation = reserveDelivery(expectedGeneration: expectedGeneration) else { return }
        defer { inFlight.leave() }
        guard let output = pixelBuffer else { return }
        CVPixelBufferLockBaseAddress(output, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(output, .readOnly) }
        deliver(output, timestamp: CMClockGetTime(CMClockGetHostTimeClock()), orientation: lastOrientation)
        scheduleRetransmission(expectedGeneration: generation)
    }

    private func beginFrame() -> Bool {
        frameLease.withLock { isBusy in
            if isBusy { return false }
            isBusy = true
            return true
        }
    }

    private func endFrame() {
        frameLease.withLock { $0 = false }
    }

    /// Called while the frame lease is held. Returns the generation a retransmission must echo.
    private func reserveDelivery(timestamp: CMTime? = nil, expectedGeneration: UInt64? = nil) -> UInt64? {
        control.withLock { state in
            guard state.capturing, state.isSessionReady, !state.paused, !state.closed else { return nil }
            if let expectedGeneration, expectedGeneration != state.timerGeneration { return nil }
            if let timestamp, state.timestampCycle == state.captureCycle, let previous = state.lastFrameTimestamp {
                let delta = CMTimeGetSeconds(CMTimeSubtract(timestamp, previous))
                if abs(delta) < Self.duplicateThresholdSeconds { return nil }
            }
            invalidateTimer(&state)
            inFlight.enter()
            return state.timerGeneration
        }
    }

    private func invalidateTimer(_ state: inout Control) {
        state.timerGeneration &+= 1
        retransmitTimer?.cancel()
        retransmitTimer = nil
    }

    private func scheduleRetransmission(expectedGeneration: UInt64) {
        let generation: UInt64? = control.withLock { state in
            guard state.capturing, state.isSessionReady, !state.paused, !state.closed else { return nil }
            guard state.timerGeneration == expectedGeneration else { return nil }
            invalidateTimer(&state)
            return state.timerGeneration
        }
        guard let generation else { return }
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: retransmitQueue)
        timer.schedule(deadline: .now() + retransmitInterval, leeway: .milliseconds(20))
        timer.setEventHandler { [weak self] in
            self?.retransmitLastFrame(expectedGeneration: generation)
        }
        let shouldStart = control.withLock { state -> Bool in
            guard state.timerGeneration == generation, !state.closed else { return false }
            retransmitTimer?.cancel()
            retransmitTimer = timer
            return true
        }
        guard shouldStart else {
            timer.cancel()
            return
        }
        timer.activate()
    }

    private func deliver(_ output: CVPixelBuffer, timestamp: CMTime, orientation: OTVideoOrientation) {
        videoFrame.timestamp = timestamp
        videoFrame.format?.estimatedCaptureDelay = 100
        videoFrame.orientation = orientation
        let planes = NSPointerArray(options: .opaqueMemory)
        planes.addPointer(CVPixelBufferGetBaseAddress(output))
        videoFrame.planes = planes
        let consumer = control.withLockUnchecked { _ in storedConsumer }
        consumer?.consumeFrame(videoFrame)
    }

    private func prepareBuffer(width srcWidth: Int, height srcHeight: Int) {
        let size = ScreenShareFrameSize.outputSize(inputWidth: srcWidth, inputHeight: srcHeight)
        let currentFormat = videoFrame.format
        guard
            currentFormat == nil
                || currentFormat?.imageWidth != UInt32(size.width)
                || currentFormat?.imageHeight != UInt32(size.height)
        else { return }

        let newFormat = OTVideoFormat(argbWithWidth: UInt32(size.width), height: UInt32(size.height))
        newFormat.bytesPerRow.removeAllObjects()
        newFormat.bytesPerRow.addObjects(from: [size.width * 4])
        videoFrame = OTVideoFrame(format: newFormat)

        var newBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            size.width,
            size.height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: false,
                kCVPixelBufferCGBitmapContextCompatibilityKey: false,
            ] as CFDictionary,
            &newBuffer)
        guard status == kCVReturnSuccess, let newBuffer else { return }
        pixelBuffer = newBuffer
    }
}
