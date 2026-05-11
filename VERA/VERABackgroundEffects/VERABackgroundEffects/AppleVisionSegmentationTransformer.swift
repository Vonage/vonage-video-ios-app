//
//  Created by Vonage on 10/5/26.
//
//  Pre-work findings (PR 1):
//  - OTVideoFrame does NOT expose a CVPixelBuffer accessor. The frame carries raw
//    planes (NSPointerArray) + format (OTVideoFormat: pixelFormat, imageWidth,
//    imageHeight, bytesPerRow array) + orientation (OTVideoOrientation).
//  - Common pixel formats: OTPixelFormatNV12, OTPixelFormatI420, OTPixelFormatARGB.
//    NV12 and I420 source frames are supported; ARGB is passed through unmodified.
//  - `CIImage(cvPixelBuffer:)` and `CIContext.render(_:to:)` both reject planar
//    I420 (Apple confirms: `pixel format y420 is not supported`). We therefore
//    use NV12 (bi-planar 4:2:0) for BOTH source and destination scratch buffers
//    and convert at the OTVideoFrame boundary:
//      - On copy-in: NV12 frame → NV12 source is a direct two-plane copy.
//                    I420 frame → NV12 source is Y direct + Cb/Cr interleave.
//      - On copy-out: NV12 dest → NV12 frame is a direct two-plane copy.
//                     NV12 dest → I420 frame is Y direct + CbCr de-interleave.
//  - Pipeline: copy frame planes into the NV12 source buffer, run Vision on it,
//    composite via CIImage, render the composite into an NV12 destination
//    buffer, then copy planes back into the source OTVideoFrame. Buffers are
//    allocated once per (width, height) tuple and reused.
//  - Orientation: cannot use UIDevice.current.orientation under "Designed for iPad
//    on Mac". The OTVideoFrame's own `orientation` property is the source of truth.
//    Mapped to CGImagePropertyOrientation in `cgOrientation(for:)`.
//

import Accelerate
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import OpenTok
import Vision
import os

/// Apple Vision-based person-segmentation transformer.
///
/// Conforms to `OTCustomVideoTransformer` so it can be wrapped via
/// `OTVideoTransformer(name:transformer:)` and registered on the publisher
/// alongside Vonage Media Library transformers.
///
/// ## Threading and lifecycle
///
/// - `transform(_:)` is called on a background thread by the Vonage SDK,
///   synchronously, at the publisher's capture frame rate (typically 30 fps).
/// - The transformer is instantiated per "blur on" event and torn down on
///   "blur off"; do not assume long-lived state between sessions.
/// - Errors must never escape `transform(_:)` — the SDK does not expect them.
public final class AppleVisionSegmentationTransformer: NSObject, OTCustomVideoTransformer {

    // MARK: - Configuration

    private let blurRadius: Float
    private let qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel

    // MARK: - Reusable pipeline state

    private let context: CIContext = {
        CIContext(options: [.useSoftwareRenderer: false])
    }()

    private lazy var segmentationRequest: VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = qualityLevel
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()

    private var sourceBuffer: CVPixelBuffer?
    private var destinationBuffer: CVPixelBuffer?
    private var bufferDescriptor: BufferDescriptor?

    private let log = Logger(subsystem: "com.vonage.VERABackgroundEffects", category: "AppleVision")
    private var hasLoggedFirstFrame = false
    private var hasLoggedVisionSuccess = false
    private var hasLoggedMaskReceived = false
    private var hasLoggedRenderComplete = false
    private var hasLoggedWritebackComplete = false

    /// Source and destination scratch buffers are always NV12 video range — see
    /// file header. The conversion to/from I420 happens at the OTVideoFrame boundary.
    private let scratchPixelFormat: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange

    // MARK: - Init

    public init(blurRadius: Float, quality: AppleVisionSegmentationQuality = .fast) {
        self.blurRadius = blurRadius
        self.qualityLevel = quality.visionQualityLevel
        super.init()
    }

    // MARK: - OTCustomVideoTransformer

    public func transform(_ videoFrame: OTVideoFrame) {
        do {
            try performTransform(videoFrame)
        } catch {
            #if DEBUG
                log.error("Vision transform failed: \(String(describing: error), privacy: .public)")
            #endif
        }
    }

    // MARK: - Pipeline

    private func performTransform(_ videoFrame: OTVideoFrame) throws {
        let frameStart = CFAbsoluteTimeGetCurrent()

        guard let format = videoFrame.format else { return }
        let width = Int(format.imageWidth)
        let height = Int(format.imageHeight)
        guard width > 0, height > 0 else { return }

        logFirstFrameIfNeeded(videoFrame, width: width, height: height)
        TransformPerformanceTracker.shared.setResolution(width: width, height: height)

        guard isSupportedFrameFormat(format.pixelFormat) else {
            // ARGB or unknown source — pass through.
            return
        }

        let descriptor = BufferDescriptor(
            width: width,
            height: height,
            sourceFormat: scratchPixelFormat,
            destinationFormat: scratchPixelFormat,
            frameFormat: format.pixelFormat
        )
        let (source, destination) = try prepareBuffers(for: descriptor)

        let copyInStart = CFAbsoluteTimeGetCurrent()
        try copyFrameIntoSource(videoFrame, into: source, descriptor: descriptor)
        let copyInEnd = CFAbsoluteTimeGetCurrent()

        // Vision
        let orientation = Self.cgOrientation(for: videoFrame.orientation)
        let handler = VNImageRequestHandler(cvPixelBuffer: source, orientation: orientation, options: [:])
        let visionStart = CFAbsoluteTimeGetCurrent()
        try handler.perform([segmentationRequest])
        let visionEnd = CFAbsoluteTimeGetCurrent()
        logOnce(&hasLoggedVisionSuccess, "Vision perform succeeded")

        guard let maskBuffer = segmentationRequest.results?.first?.pixelBuffer else {
            #if DEBUG
                log.error("Vision returned no mask")
            #endif
            return
        }
        logOnceMaskReceived(maskBuffer)
        let compositeStart = CFAbsoluteTimeGetCurrent()

        // Composite: blur the source, then blend source over blurred using the mask.
        // Vision's person mask is white on the person and black on the background, so
        //   inputImage      = sourceImage (kept where mask is white)
        //   backgroundImage = blurred     (kept where mask is black)
        let sourceImage = CIImage(cvPixelBuffer: source)

        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = sourceImage
        blurFilter.radius = blurRadius
        guard let blurred = blurFilter.outputImage?.cropped(to: sourceImage.extent) else { return }

        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let maskScaleX = sourceImage.extent.width / maskImage.extent.width
        let maskScaleY = sourceImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: maskScaleX, y: maskScaleY))

        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = sourceImage
        blendFilter.backgroundImage = blurred
        blendFilter.maskImage = scaledMask
        guard let composite = blendFilter.outputImage else { return }

        context.render(composite, to: destination)
        logOnce(&hasLoggedRenderComplete, "Render to NV12 destination complete")
        let compositeEnd = CFAbsoluteTimeGetCurrent()

        let copyOutStart = CFAbsoluteTimeGetCurrent()
        copyDestinationIntoFrame(destination, into: videoFrame, descriptor: descriptor)
        logOnce(&hasLoggedWritebackComplete, "Writeback to OTVideoFrame complete")
        let copyOutEnd = CFAbsoluteTimeGetCurrent()

        let frameEnd = CFAbsoluteTimeGetCurrent()
        TransformPerformanceTracker.shared.record(
            transformMs: (frameEnd - frameStart) * 1000,
            visionMs: (visionEnd - visionStart) * 1000,
            copyInMs: (copyInEnd - copyInStart) * 1000,
            compositeMs: (compositeEnd - compositeStart) * 1000,
            copyOutMs: (copyOutEnd - copyOutStart) * 1000
        )
    }

    // MARK: - Buffer management

    private struct BufferDescriptor: Equatable {
        let width: Int
        let height: Int
        let sourceFormat: OSType
        let destinationFormat: OSType
        let frameFormat: OTPixelFormat

        static func == (lhs: BufferDescriptor, rhs: BufferDescriptor) -> Bool {
            lhs.width == rhs.width && lhs.height == rhs.height && lhs.sourceFormat == rhs.sourceFormat
                && lhs.destinationFormat == rhs.destinationFormat && lhs.frameFormat == rhs.frameFormat
        }
    }

    private func prepareBuffers(
        for descriptor: BufferDescriptor
    ) throws -> (
        source: CVPixelBuffer, destination: CVPixelBuffer
    ) {
        if descriptor != bufferDescriptor {
            sourceBuffer = try makePixelBuffer(
                width: descriptor.width, height: descriptor.height, format: descriptor.sourceFormat)
            destinationBuffer = try makePixelBuffer(
                width: descriptor.width, height: descriptor.height, format: descriptor.destinationFormat)
            bufferDescriptor = descriptor
        }
        guard let source = sourceBuffer, let destination = destinationBuffer else {
            throw TransformError.pixelBufferAllocationFailed
        }
        return (source, destination)
    }

    private func makePixelBuffer(width: Int, height: Int, format: OSType) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
            kCVPixelBufferMetalCompatibilityKey: true,
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, width, height, format, attributes as CFDictionary, &buffer)
        guard status == kCVReturnSuccess, let result = buffer else {
            throw TransformError.pixelBufferAllocationFailed
        }
        return result
    }

    // MARK: - Plane copy: frame → NV12 source buffer

    private func copyFrameIntoSource(
        _ frame: OTVideoFrame, into pixelBuffer: CVPixelBuffer, descriptor: BufferDescriptor
    ) throws {
        // Source buffer is NV12. The frame may be NV12 (direct copy) or I420
        // (Y direct, Cb+Cr interleaved into the NV12 CbCr plane).
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        switch descriptor.frameFormat {
        case .NV12:
            copyPlaneFromFrame(into: pixelBuffer, bufferPlane: 0, frame: frame, framePlane: 0)
            copyPlaneFromFrame(into: pixelBuffer, bufferPlane: 1, frame: frame, framePlane: 1)

        case .I420:
            copyPlaneFromFrame(into: pixelBuffer, bufferPlane: 0, frame: frame, framePlane: 0)
            interleaveCbCr(intoBuffer: pixelBuffer, bufferPlane: 1, frame: frame, cbPlane: 1, crPlane: 2)

        default:
            break
        }
    }

    private func copyPlaneFromFrame(
        into pixelBuffer: CVPixelBuffer, bufferPlane: Int, frame: OTVideoFrame, framePlane: Int
    ) {
        guard let dst = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, bufferPlane) else { return }
        let dstStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, bufferPlane)
        let rows = CVPixelBufferGetHeightOfPlane(pixelBuffer, bufferPlane)
        let src = frame.getPlaneBinaryData(Int32(framePlane))
        let srcStride = Int(frame.getPlaneStride(Int32(framePlane)))
        let copyStride = min(dstStride, srcStride)
        for row in 0..<rows {
            memcpy(
                dst.advanced(by: row * dstStride),
                src.advanced(by: row * srcStride),
                copyStride
            )
        }
    }

    /// Interleaves separate Cb and Cr planes from an I420 frame into a single NV12
    /// `CbCrCbCr…` plane on the destination buffer.
    ///
    /// Uses `vImageConvert_Planar8toChunky8` (Accelerate / NEON-vectorized) instead
    /// of a Swift inner loop — the latter was the dominant cost at 1080p (~60 ms
    /// per call) because Swift's pixel-wise scalar loop is not auto-vectorized.
    private func interleaveCbCr(
        intoBuffer pixelBuffer: CVPixelBuffer, bufferPlane: Int,
        frame: OTVideoFrame, cbPlane: Int, crPlane: Int
    ) {
        guard let dstRaw = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, bufferPlane) else { return }
        let dstStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, bufferPlane)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, bufferPlane)
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, bufferPlane)

        let cb = frame.getPlaneBinaryData(Int32(cbPlane))
        let cbStride = Int(frame.getPlaneStride(Int32(cbPlane)))
        let cr = frame.getPlaneBinaryData(Int32(crPlane))
        let crStride = Int(frame.getPlaneStride(Int32(crPlane)))

        var cbBuf = vImage_Buffer(
            data: UnsafeMutableRawPointer(cb),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: cbStride
        )
        var crBuf = vImage_Buffer(
            data: UnsafeMutableRawPointer(cr),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: crStride
        )

        withUnsafePointer(to: &cbBuf) { cbPtr in
            withUnsafePointer(to: &crBuf) { crPtr in
                var planarPtrs: [UnsafePointer<vImage_Buffer>?] = [cbPtr, crPtr]
                var destChannels: [UnsafeMutableRawPointer?] = [
                    dstRaw,
                    dstRaw.advanced(by: 1),
                ]
                planarPtrs.withUnsafeMutableBufferPointer { planarBuf in
                    destChannels.withUnsafeMutableBufferPointer { channelsBuf in
                        _ = vImageConvert_PlanarToChunky8(
                            planarBuf.baseAddress!,
                            channelsBuf.baseAddress!,
                            2,
                            2,
                            vImagePixelCount(width),
                            vImagePixelCount(height),
                            dstStride,
                            vImage_Flags(kvImageNoFlags)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Plane copy: destination buffer (NV12) → frame

    private func copyDestinationIntoFrame(
        _ pixelBuffer: CVPixelBuffer, into frame: OTVideoFrame, descriptor: BufferDescriptor
    ) {
        // Destination buffer is always NV12 (two planes: Y + interleaved CbCr).
        // The frame's format determines how we lay it back down.
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        switch descriptor.frameFormat {
        case .NV12:
            // Same format — direct two-plane copy.
            copyPlane(from: pixelBuffer, plane: 0, intoFrame: frame, framePlane: 0)
            copyPlane(from: pixelBuffer, plane: 1, intoFrame: frame, framePlane: 1)

        case .I420:
            // NV12 → I420: Y plane direct, then de-interleave CbCr → separate Cb and Cr.
            copyPlane(from: pixelBuffer, plane: 0, intoFrame: frame, framePlane: 0)
            deinterleaveCbCr(from: pixelBuffer, plane: 1, intoFrame: frame, cbPlane: 1, crPlane: 2)

        default:
            break
        }
    }

    private func copyPlane(
        from pixelBuffer: CVPixelBuffer, plane: Int, intoFrame frame: OTVideoFrame, framePlane: Int
    ) {
        guard let src = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane) else { return }
        let srcStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
        let rows = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
        let dst = frame.getPlaneBinaryData(Int32(framePlane))
        let dstStride = Int(frame.getPlaneStride(Int32(framePlane)))
        let copyStride = min(dstStride, srcStride)
        for row in 0..<rows {
            memcpy(
                dst.advanced(by: row * dstStride),
                src.advanced(by: row * srcStride),
                copyStride
            )
        }
    }

    /// De-interleaves an NV12 CbCr plane (`CbCrCbCr…`) into separate Cb and Cr planes
    /// of an I420 frame. The chroma plane is half-width and half-height.
    ///
    /// Uses `vImageConvert_ChunkyToPlanar8` for the same reason as
    /// ``interleaveCbCr(intoBuffer:bufferPlane:frame:cbPlane:crPlane:)``:
    /// the Swift inner loop dominated CPU time at 1080p.
    private func deinterleaveCbCr(
        from pixelBuffer: CVPixelBuffer, plane: Int,
        intoFrame frame: OTVideoFrame, cbPlane: Int, crPlane: Int
    ) {
        guard let srcRaw = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane) else { return }
        let srcStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, plane)

        let cb = frame.getPlaneBinaryData(Int32(cbPlane))
        let cbStride = Int(frame.getPlaneStride(Int32(cbPlane)))
        let cr = frame.getPlaneBinaryData(Int32(crPlane))
        let crStride = Int(frame.getPlaneStride(Int32(crPlane)))

        var cbBuf = vImage_Buffer(
            data: UnsafeMutableRawPointer(cb),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: cbStride
        )
        var crBuf = vImage_Buffer(
            data: UnsafeMutableRawPointer(cr),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: crStride
        )

        withUnsafePointer(to: &cbBuf) { cbPtr in
            withUnsafePointer(to: &crBuf) { crPtr in
                var planarPtrs: [UnsafePointer<vImage_Buffer>?] = [cbPtr, crPtr]
                var srcChannels: [UnsafeRawPointer?] = [
                    UnsafeRawPointer(srcRaw),
                    UnsafeRawPointer(srcRaw).advanced(by: 1),
                ]
                planarPtrs.withUnsafeMutableBufferPointer { planarBuf in
                    srcChannels.withUnsafeMutableBufferPointer { channelsBuf in
                        _ = vImageConvert_ChunkyToPlanar8(
                            channelsBuf.baseAddress!,
                            planarBuf.baseAddress!,
                            2,
                            2,
                            vImagePixelCount(width),
                            vImagePixelCount(height),
                            srcStride,
                            vImage_Flags(kvImageNoFlags)
                        )
                    }
                }
            }
        }
    }

    private func planeCount(for cvFormat: OSType) -> Int {
        switch cvFormat {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            return 2
        case kCVPixelFormatType_420YpCbCr8Planar,
            kCVPixelFormatType_420YpCbCr8PlanarFullRange:
            return 3
        default:
            return 0
        }
    }

    private func isSupportedFrameFormat(_ otFormat: OTPixelFormat) -> Bool {
        switch otFormat {
        case .NV12, .I420: return true
        case .ARGB: return false
        @unknown default: return false
        }
    }

    // MARK: - Diagnostics

    private func logFirstFrameIfNeeded(_ videoFrame: OTVideoFrame, width: Int, height: Int) {
        guard !hasLoggedFirstFrame else { return }
        hasLoggedFirstFrame = true

        let pixelFormatString =
            videoFrame.format.map { format in
                let code = UInt32(bitPattern: format.pixelFormat.rawValue)
                let bytes: [UInt8] = [
                    UInt8(truncatingIfNeeded: code >> 24),
                    UInt8(truncatingIfNeeded: code >> 16),
                    UInt8(truncatingIfNeeded: code >> 8),
                    UInt8(truncatingIfNeeded: code),
                ]
                return String(bytes: bytes, encoding: .ascii) ?? "?"
            } ?? "nil"

        log.info(
            """
            First frame received: pixelFormat=\(pixelFormatString, privacy: .public) \
            size=\(width, privacy: .public)x\(height, privacy: .public) \
            orientation=\(videoFrame.orientation.rawValue, privacy: .public) \
            quality=\(self.qualityLevel.rawValue, privacy: .public)
            """
        )
    }

    private func logOnce(_ flag: inout Bool, _ message: String) {
        guard !flag else { return }
        flag = true
        log.info("\(message, privacy: .public)")
    }

    private func logOnceMaskReceived(_ buffer: CVPixelBuffer) {
        guard !hasLoggedMaskReceived else { return }
        hasLoggedMaskReceived = true
        let w = CVPixelBufferGetWidth(buffer)
        let h = CVPixelBufferGetHeight(buffer)
        log.info("Mask received: size=\(w, privacy: .public)x\(h, privacy: .public)")
    }

    // MARK: - Errors

    enum TransformError: Swift.Error {
        case pixelBufferAllocationFailed
    }

    // MARK: - Orientation

    nonisolated static func cgOrientation(for otOrientation: OTVideoOrientation) -> CGImagePropertyOrientation {
        switch otOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        @unknown default: return .up
        }
    }
}

// MARK: - Quality bridging

extension AppleVisionSegmentationQuality {
    var visionQualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel {
        switch self {
        case .fast: return .fast
        case .balanced: return .balanced
        case .accurate: return .accurate
        }
    }
}
