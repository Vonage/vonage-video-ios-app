//
//  Created by Vonage on 21/6/26.
//

import Accelerate
import Foundation
import OpenTok

/// Converts I420 video frames from the Vonage SDK into BGRA pixel buffers for PiP sample buffers.
final class YUVToARGBAccelerator {
    private var infoYpCbCrToARGB = vImage_YpCbCrToARGB()

    init() {
        _ = configureYpCbCrToARGBInfo()
    }

    /// Rotates a BGRA pixel buffer 90° clockwise into `dest`, which must have its width/height
    /// swapped relative to `source`. Locks both buffers. Change the rotation constant to `3` for
    /// counter-clockwise.
    func rotate90Clockwise(_ source: CVPixelBuffer, to dest: CVPixelBuffer) -> vImage_Error {
        CVPixelBufferLockBaseAddress(source, .readOnly)
        CVPixelBufferLockBaseAddress(dest, [])
        defer {
            CVPixelBufferUnlockBaseAddress(source, .readOnly)
            CVPixelBufferUnlockBaseAddress(dest, [])
        }

        var src = vImage_Buffer(
            data: CVPixelBufferGetBaseAddress(source),
            height: vImagePixelCount(CVPixelBufferGetHeight(source)),
            width: vImagePixelCount(CVPixelBufferGetWidth(source)),
            rowBytes: CVPixelBufferGetBytesPerRow(source))
        var dst = vImage_Buffer(
            data: CVPixelBufferGetBaseAddress(dest),
            height: vImagePixelCount(CVPixelBufferGetHeight(dest)),
            width: vImagePixelCount(CVPixelBufferGetWidth(dest)),
            rowBytes: CVPixelBufferGetBytesPerRow(dest))
        var backColor: [UInt8] = [0, 0, 0, 0]
        return vImageRotate90_ARGB8888(&src, &dst, UInt8(1), &backColor, vImage_Flags(kvImageNoFlags))
    }

    private func configureYpCbCrToARGBInfo() -> vImage_Error {
        var pixelRange = vImage_YpCbCrPixelRange(
            Yp_bias: 0,
            CbCr_bias: 128,
            YpRangeMax: 255,
            CbCrRangeMax: 255,
            YpMax: 255,
            YpMin: 1,
            CbCrMax: 255,
            CbCrMin: 0
        )

        return vImageConvert_YpCbCrToARGB_GenerateConversion(
            kvImage_YpCbCrToARGBMatrix_ITU_R_601_4!,
            &pixelRange,
            &infoYpCbCrToARGB,
            kvImage420Yp8_Cb8_Cr8,
            kvImageARGB8888,
            vImage_Flags(kvImageNoFlags)
        )
    }

    /// - Parameter mirrored: horizontally reflects the output. Used only for the local publisher's
    ///   self-view (front-camera selfie convention); remote streams are never mirrored. Reflecting
    ///   the pixels (rather than transforming the layer) keeps every surface fed by the renderer
    ///   — the tile and the PiP window — consistent.
    func convertFrameVImageYUV(
        _ frame: OTVideoFrame,
        to pixelBufferRef: CVPixelBuffer?,
        mirrored: Bool = false
    ) -> vImage_Error {
        guard let pixelBufferRef, let format = frame.format, let planes = frame.planes else {
            return vImage_Error(kvImageInvalidParameter)
        }

        let width = Int(format.imageWidth)
        let height = Int(format.imageHeight)
        let subsampledWidth = width / 2
        let subsampledHeight = height / 2

        // Each plane's real row stride, which can exceed the visible width when the SDK pads rows
        // for alignment (e.g. widths not a multiple of 16). Falling back to a tightly-packed stride.
        let yStride = format.bytesPerRow.object(at: 0) as? Int ?? width
        let uStride = format.bytesPerRow.object(at: 1) as? Int ?? subsampledWidth
        let vStride = format.bytesPerRow.object(at: 2) as? Int ?? subsampledWidth

        // Point vImage directly at the SDK's frame planes (valid for the duration of this callback)
        // using each plane's real stride. This avoids a per-frame allocate + memcpy of all three
        // planes, and — by honoring the source stride instead of assuming stride == width — reads
        // padded rows correctly rather than over-reading a tightly-packed copy.
        var yPlaneBuffer = vImage_Buffer(
            data: planes.pointer(at: 0),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: yStride
        )
        var uPlaneBuffer = vImage_Buffer(
            data: planes.pointer(at: 1),
            height: vImagePixelCount(subsampledHeight),
            width: vImagePixelCount(subsampledWidth),
            rowBytes: uStride
        )
        var vPlaneBuffer = vImage_Buffer(
            data: planes.pointer(at: 2),
            height: vImagePixelCount(subsampledHeight),
            width: vImagePixelCount(subsampledWidth),
            rowBytes: vStride
        )

        CVPixelBufferLockBaseAddress(pixelBufferRef, [])
        let pixelBufferData = CVPixelBufferGetBaseAddress(pixelBufferRef)
        let rowBytes = CVPixelBufferGetBytesPerRow(pixelBufferRef)
        var destinationImageBuffer = vImage_Buffer(
            data: pixelBufferData,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: rowBytes
        )

        var permuteMap: [UInt8] = [3, 2, 1, 0]
        let convertError = vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(
            &yPlaneBuffer,
            &uPlaneBuffer,
            &vPlaneBuffer,
            &destinationImageBuffer,
            &infoYpCbCrToARGB,
            &permuteMap,
            255,
            vImage_Flags(kvImageNoFlags)
        )

        if mirrored {
            _ = vImageHorizontalReflect_ARGB8888(
                &destinationImageBuffer,
                &destinationImageBuffer,
                vImage_Flags(kvImageNoFlags)
            )
        }

        CVPixelBufferUnlockBaseAddress(pixelBufferRef, [])

        return convertError
    }
}
