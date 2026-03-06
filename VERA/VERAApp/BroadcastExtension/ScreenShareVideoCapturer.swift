//
//  Created by Vonage on 26/2/26.
//

import CoreImage
import CoreMedia
import CoreVideo
import Foundation
import OpenTok
import ReplayKit

/// Feeds ReplayKit `CMSampleBuffer` frames into the Vonage SDK.
///
/// - An owned `CVPixelBuffer` is created in `checkSize` and reused across frames.
/// - `CIContext.render(_:to:)` writes scaled BGRA pixels directly into the
///   destination buffer — the layout Vonage reads correctly when told pixelFormat = .ARGB.
/// - `captureSettings` only sets `pixelFormat`; `bytesPerRow` is populated by
///   `checkSize` before the first frame, preventing the `NSRangeException`.
/// - The last frame is retransmitted every ~250 ms during static content so
///   subscribers always have a fresh frame and the SDK can estimate bandwidth.
/// - Frames with near-identical timestamps (< 2 ms apart) are dropped to avoid
///   wasting encoder time on duplicate ReplayKit output.
final class ScreenShareVideoCapturer: NSObject, OTVideoCapture {
    var videoContentHint: OTVideoContentHint = .text
    var videoCaptureConsumer: OTVideoCaptureConsumer?

    // Matches the Android implementation: cap the longest edge at 1280px.
    // Dimensions must be multiples of edgeDimensionCommonFactor for codec alignment.
    let maxEdgeSizeLimit: CGFloat = 1280
    let edgeDimensionCommonFactor: CGFloat = 16

    fileprivate var capturing: Bool = false
    fileprivate var isSessionReady: Bool = false

    // Matches the reference: initialised with (0, 0) so checkSize always fires on
    // the first frame and populates bytesPerRow before consumeFrame is called.
    fileprivate var videoFrame = OTVideoFrame(format: OTVideoFormat(argbWithWidth: 0, height: 0))
    fileprivate var pixelBuffer: CVPixelBuffer?  // destination buffer (capped size, BGRA)
    // Retain the previous CMSampleBuffer so ReplayKit cannot reuse the underlying
    // CVPixelBuffer while we are still rendering from it (prevents tearing).
    fileprivate var lastSampleBuffer: CMSampleBuffer?
    fileprivate let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // Frame retransmission — resend the last frame every ~250ms during static content
    // so subscribers always have a fresh frame and the SDK can estimate bandwidth.
    private static let retransmitIntervalMs = 250
    private let frameLock = NSLock()
    private let retransmitQueue = DispatchQueue(label: "com.vonage.VERA.screenshare.retransmit")
    private var retransmitTimer: DispatchSourceTimer?
    private var lastOrientation: OTVideoOrientation = .up
    // Duplicate frame detection — skip frames whose timestamp is within this
    // threshold of the previous, as they carry identical pixel content.
    private static let duplicateThresholdSeconds: Double = 0.002
    private var lastFrameTimestamp: CMTime?

    // MARK: - Session readiness

    func sessionDidConnect() {
        isSessionReady = true
    }

    func sessionDidDisconnect() {
        isSessionReady = false
    }

    // MARK: - OTVideoCapture

    func initCapture() {}
    func releaseCapture() {}

    func start() -> Int32 {
        capturing = true
        return 0
    }

    func stop() -> Int32 {
        capturing = false
        retransmitTimer?.cancel()
        retransmitTimer = nil
        return 0
    }

    func isCaptureStarted() -> Bool {
        capturing
    }

    // Only pixelFormat is set here — matches the reference exactly.
    // bytesPerRow is populated by checkSize before the first consumeFrame.
    func captureSettings(_ videoFormat: OTVideoFormat) -> Int32 {
        videoFormat.pixelFormat = .ARGB
        return 0
    }

    // MARK: - Frame ingestion

    func consumeVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard capturing,
            isSessionReady,
            let srcBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        // Skip duplicate frames — ReplayKit can deliver frames with nearly identical
        // timestamps when the screen content hasn't changed.
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if let lastPTS = lastFrameTimestamp {
            let delta = CMTimeGetSeconds(CMTimeSubtract(pts, lastPTS))
            if abs(delta) < Self.duplicateThresholdSeconds {
                return
            }
        }
        lastFrameTimestamp = pts

        let orientation = sampleOrientation(from: sampleBuffer)
        let ciImage = CIImage(cvPixelBuffer: srcBuffer)
        let extent = ciImage.extent
        checkSize(width: Int(extent.width), height: Int(extent.height))
        guard let dstBuffer = pixelBuffer else { return }

        frameLock.lock()

        CVPixelBufferLockBaseAddress(dstBuffer, [])

        let dstWidth = CVPixelBufferGetWidth(dstBuffer)
        let dstHeight = CVPixelBufferGetHeight(dstBuffer)

        // Scale the source image to fit the destination buffer, then render directly.
        let scaleX = CGFloat(dstWidth) / extent.width
        let scaleY = CGFloat(dstHeight) / extent.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        ciContext.render(
            scaledImage, to: dstBuffer, bounds: scaledImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())

        // Pass the actual orientation so the receiving side can rotate correctly.
        videoFrame.timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        videoFrame.format?.estimatedCaptureDelay = 100
        videoFrame.orientation = orientation.otOrientation
        lastOrientation = orientation.otOrientation
        let planes = NSPointerArray(options: .opaqueMemory)
        planes.addPointer(CVPixelBufferGetBaseAddress(dstBuffer))
        videoFrame.planes = planes
        videoCaptureConsumer?.consumeFrame(videoFrame)

        CVPixelBufferUnlockBaseAddress(dstBuffer, [])

        frameLock.unlock()

        lastSampleBuffer = sampleBuffer
        scheduleRetransmission()
    }

    /// Reads the video orientation from the ReplayKit sample buffer attachment.
    private func sampleOrientation(
        from sampleBuffer: CMSampleBuffer
    ) -> CGImagePropertyOrientation {
        guard
            let value = CMGetAttachment(
                sampleBuffer,
                key: RPVideoSampleOrientationKey as CFString,
                attachmentModeOut: nil),
            let rawValue = (value as? NSNumber)?.uint32Value
        else {
            return .up
        }
        return CGImagePropertyOrientation(rawValue: rawValue) ?? .up
    }

    // MARK: - Frame retransmission

    /// Schedules a timer to resend the last frame if no new frame arrives within the interval.
    private func scheduleRetransmission() {
        retransmitTimer?.cancel()

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: retransmitQueue)
        timer.schedule(
            deadline: .now() + .milliseconds(Self.retransmitIntervalMs),
            leeway: .milliseconds(20)
        )
        timer.setEventHandler { [weak self] in
            self?.retransmitLastFrame()
        }
        timer.activate()
        retransmitTimer = timer
    }

    /// Re-delivers the current destination buffer with an updated timestamp.
    private func retransmitLastFrame() {
        frameLock.lock()
        defer { frameLock.unlock() }

        guard capturing, isSessionReady, let dstBuffer = pixelBuffer else { return }

        CVPixelBufferLockBaseAddress(dstBuffer, .readOnly)

        videoFrame.timestamp = CMClockGetTime(CMClockGetHostTimeClock())
        videoFrame.format?.estimatedCaptureDelay = 100
        videoFrame.orientation = lastOrientation
        let planes = NSPointerArray(options: .opaqueMemory)
        planes.addPointer(CVPixelBufferGetBaseAddress(dstBuffer))
        videoFrame.planes = planes
        videoCaptureConsumer?.consumeFrame(videoFrame)

        CVPixelBufferUnlockBaseAddress(dstBuffer, .readOnly)

        // Reschedule for the next interval.
        scheduleRetransmission()
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
    /// Returns output dimensions capped at `maxEdgeSizeLimit` on the longest edge,
    /// rounded up to the nearest multiple of `edgeDimensionCommonFactor` for codec alignment.
    fileprivate func outputSize(for inputWidth: Int, _ inputHeight: Int) -> (width: Int, height: Int) {
        var w = CGFloat(inputWidth)
        var h = CGFloat(inputHeight)
        let longest = max(w, h)
        if longest > maxEdgeSizeLimit {
            let scale = maxEdgeSizeLimit / longest
            w = (w * scale).rounded()
            h = (h * scale).rounded()
        }
        let align = { (v: CGFloat) -> Int in
            let r = v.truncatingRemainder(dividingBy: self.edgeDimensionCommonFactor)
            return r == 0 ? Int(v) : Int(v + (self.edgeDimensionCommonFactor - r))
        }
        return (align(w), align(h))
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
