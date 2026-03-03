//
//  Created by Vonage on 26/2/26.
//

import CoreImage
import CoreMedia
import CoreVideo
import Foundation
import OpenTok

/// Feeds ReplayKit `CMSampleBuffer` frames into the Vonage SDK.
///
/// Follows the same pattern as the official Vonage `ScreenCapturer` sample:
/// - An owned `CVPixelBuffer` is created in `checkSize` and reused across frames.
/// - A `CGContext` with `premultipliedFirst | byteOrder32Little` writes BGRA bytes
///   in memory — the layout Vonage reads correctly when told pixelFormat = .ARGB.
/// - Scaling to the capped destination size is handled by CGContext.draw(_:in:).
/// - `captureSettings` only sets `pixelFormat`; `bytesPerRow` is populated by
///   `checkSize` before the first frame, preventing the `NSRangeException`.
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
    fileprivate let ciContext = CIContext(options: [.useSoftwareRenderer: false])

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

        checkSize(forPixelBuffer: srcBuffer)
        guard let dstBuffer = pixelBuffer else { return }

        CVPixelBufferLockBaseAddress(dstBuffer, [])

        let dstWidth = CVPixelBufferGetWidth(dstBuffer)
        let dstHeight = CVPixelBufferGetHeight(dstBuffer)

        // Mirrors the official ScreenCapturer sample exactly:
        // CGContext with premultipliedFirst | byteOrder32Little writes BGRA bytes in
        // memory — the layout Vonage reads correctly when told pixelFormat = .ARGB.
        // draw(_:in:) handles both copy and scale in one step without vImage.
        let ciImage = CIImage(cvPixelBuffer: srcBuffer)
        if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent),
            let ctx = CGContext(
                data: CVPixelBufferGetBaseAddress(dstBuffer),
                width: dstWidth,
                height: dstHeight,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(dstBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue
            )
        {
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: dstWidth, height: dstHeight))
        }

        // consumeFrame is synchronous — keep dstBuffer locked until it returns.
        videoFrame.timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        videoFrame.format?.estimatedCaptureDelay = 100
        videoFrame.orientation = .up
        videoFrame.clearPlanes()
        videoFrame.planes?.addPointer(CVPixelBufferGetBaseAddress(dstBuffer))
        videoCaptureConsumer?.consumeFrame(videoFrame)

        CVPixelBufferUnlockBaseAddress(dstBuffer, [])
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

    fileprivate func checkSize(forPixelBuffer buffer: CVPixelBuffer) {
        let srcWidth = Int(CVPixelBufferGetWidth(buffer))
        let srcHeight = Int(CVPixelBufferGetHeight(buffer))
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
