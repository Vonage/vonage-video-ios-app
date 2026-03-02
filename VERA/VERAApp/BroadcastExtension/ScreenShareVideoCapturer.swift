import Accelerate
import CoreMedia
import CoreVideo
import Foundation
import OpenTok

/// Feeds ReplayKit `CMSampleBuffer` frames into the Vonage SDK.
///
/// Follows the same pattern as the official Vonage `ScreenCapturer` sample:
/// - An owned `CVPixelBuffer` is created in `checkSize` and reused across frames.
/// - The BGRA source is converted to ARGB via `vImagePermuteChannels_ARGB8888`,
///   which correctly handles each buffer's individual stride.
/// - The owned buffer is locked for the duration of `consumeFrame` (synchronous),
///   then unlocked immediately after — this avoids `EXC_BAD_ACCESS`.
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
    fileprivate var pixelBuffer: CVPixelBuffer?      // destination buffer (capped size, ARGB)
    fileprivate var tempPixelBuffer: CVPixelBuffer?  // intermediate buffer (source size, ARGB) — reused every frame when downscaling

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

        CVPixelBufferLockBaseAddress(srcBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(dstBuffer, [])

        let srcWidth = CVPixelBufferGetWidth(srcBuffer)
        let srcHeight = CVPixelBufferGetHeight(srcBuffer)
        let dstWidth = CVPixelBufferGetWidth(dstBuffer)
        let dstHeight = CVPixelBufferGetHeight(dstBuffer)

        // Scale BGRA source into ARGB destination using vImage.
        // When srcSize == dstSize, vImageScale is a no-op pass-through.
        // Channel map [3,2,1,0] reorders B0 G1 R2 A3 → A3 R2 G1 B0 = ARGB.
        if let srcBase = CVPixelBufferGetBaseAddress(srcBuffer),
           let dstBase = CVPixelBufferGetBaseAddress(dstBuffer) {
            // Intermediate same-size ARGB buffer to hold the channel-permuted source.
            var src = vImage_Buffer(
                data: srcBase,
                height: vImagePixelCount(srcHeight),
                width: vImagePixelCount(srcWidth),
                rowBytes: CVPixelBufferGetBytesPerRow(srcBuffer)
            )
            var dst = vImage_Buffer(
                data: dstBase,
                height: vImagePixelCount(dstHeight),
                width: vImagePixelCount(dstWidth),
                rowBytes: CVPixelBufferGetBytesPerRow(dstBuffer)
            )
            if srcWidth == dstWidth && srcHeight == dstHeight {
                // No scaling needed — permute BGRA→ARGB directly into dst.
                let map: [UInt8] = [3, 2, 1, 0]
                vImagePermuteChannels_ARGB8888(&src, &dst, map, vImage_Flags(kvImageNoFlags))
            } else if let tmpBuffer = tempPixelBuffer,
                      let tmpBase = CVPixelBufferGetBaseAddress(tmpBuffer) {
                // Permute BGRA→ARGB into the pre-allocated temp buffer, then scale into dst.
                // tempPixelBuffer is allocated once in checkSize — no per-frame heap alloc.
                CVPixelBufferLockBaseAddress(tmpBuffer, [])
                var temp = vImage_Buffer(
                    data: tmpBase,
                    height: vImagePixelCount(srcHeight),
                    width: vImagePixelCount(srcWidth),
                    rowBytes: CVPixelBufferGetBytesPerRow(tmpBuffer)
                )
                let map: [UInt8] = [3, 2, 1, 0]
                vImagePermuteChannels_ARGB8888(&src, &temp, map, vImage_Flags(kvImageNoFlags))
                vImageScale_ARGB8888(&temp, &dst, nil, vImage_Flags(kvImageHighQualityResampling))
                CVPixelBufferUnlockBaseAddress(tmpBuffer, [])
            }
        }

        // Set frame fields and call consumeFrame while dstBuffer is still locked.
        // consumeFrame is synchronous — the SDK reads the plane pointer before returning.
        videoFrame.timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        videoFrame.format?.estimatedCaptureDelay = 100
        videoFrame.orientation = .up
        videoFrame.clearPlanes()
        videoFrame.planes?.addPointer(CVPixelBufferGetBaseAddress(dstBuffer))
        videoCaptureConsumer?.consumeFrame(videoFrame)

        // Unlock only after consumeFrame has returned.
        CVPixelBufferUnlockBaseAddress(dstBuffer, [])
        CVPixelBufferUnlockBaseAddress(srcBuffer, .readOnly)
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

        guard let frameFormat = videoFrame.format,
              frameFormat.imageWidth != UInt32(width) || frameFormat.imageHeight != UInt32(height)
        else { return }

        frameFormat.bytesPerRow.removeAllObjects()
        frameFormat.bytesPerRow.addObjects(from: [width * 4])
        frameFormat.imageWidth = UInt32(width)
        frameFormat.imageHeight = UInt32(height)

        var newBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            [
                kCVPixelBufferCGImageCompatibilityKey: false,
                kCVPixelBufferCGBitmapContextCompatibilityKey: false
            ] as CFDictionary,
            &newBuffer
        )
        assert(status == kCVReturnSuccess && newBuffer != nil)
        pixelBuffer = newBuffer

        // Allocate the intermediate buffer at source resolution only when downscaling.
        // Reused every frame to avoid per-frame heap allocations.
        if srcWidth != width || srcHeight != height {
            var newTempBuffer: CVPixelBuffer?
            CVPixelBufferCreate(
                kCFAllocatorDefault,
                srcWidth,
                srcHeight,
                kCVPixelFormatType_32ARGB,
                [
                    kCVPixelBufferCGImageCompatibilityKey: false,
                    kCVPixelBufferCGBitmapContextCompatibilityKey: false
                ] as CFDictionary,
                &newTempBuffer
            )
            tempPixelBuffer = newTempBuffer
        } else {
            tempPixelBuffer = nil
        }
    }
}
