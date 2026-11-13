import AVFoundation
import Accelerate
import Foundation
import OpenTok
import Testing
import UIKit

@testable import VERAVonage

@MainActor
@Suite("PiP borrowed frame delivery")
struct PictureInPictureFrameIsolationTests {
    @Test("Concurrent background frames share synchronized conversion state")
    func rendersConcurrentBorrowedFramesWithoutMainActorHop() {
        let renderer = PictureInPictureVideoRenderer()
        renderer.pipBufferDisplayLayer = AVSampleBufferDisplayLayer()
        let fixture = I420TestFrame()
        let callbacks = DispatchGroup()
        let frameCount = 12

        for _ in 0..<frameCount {
            callbacks.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                fixture.withFrame { renderer.renderVideoFrame($0) }
                callbacks.leave()
            }
        }
        // UI-owned changes may overlap a callback, but never expose converter or pool state.
        for index in 0..<16 {
            renderer.isMirrored = index.isMultiple(of: 2)
        }

        let finished = callbacks.wait(timeout: .now() + 3) == .success
        #expect(finished, "Frame delivery must finish while the UI actor is occupied")
        guard finished else { return }
        #expect(renderer.renderedFrameCount == frameCount)
    }

    @Test("An active placeholder suppresses trailing camera frames before video resumes")
    func suppressesBackgroundFramesUntilPlaceholderStops() {
        let renderer = PictureInPictureVideoRenderer()
        let fixture = I420TestFrame()
        renderer.startPlaceholder(name: "Alice")
        defer { renderer.stopPlaceholder() }
        let countBeforeCameraFrames = renderer.renderedFrameCount

        let suppressed = deliverBackgroundFrames(8, fixture: fixture, to: renderer)
        #expect(suppressed)
        guard suppressed else { return }
        // This synchronous test occupies MainActor, so the avatar timer cannot affect the count.
        #expect(renderer.renderedFrameCount == countBeforeCameraFrames)
        #expect(renderer.isPlaceholderActive)

        renderer.stopPlaceholder()
        let resumed = deliverBackgroundFrames(1, fixture: fixture, to: renderer)
        #expect(resumed)
        guard resumed else { return }
        #expect(renderer.renderedFrameCount == countBeforeCameraFrames + 1)
    }

    private func deliverBackgroundFrames(
        _ count: Int, fixture: I420TestFrame, to renderer: PictureInPictureVideoRenderer
    ) -> Bool {
        let callbacks = DispatchGroup()
        callbacks.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            for _ in 0..<count {
                fixture.withFrame { renderer.renderVideoFrame($0) }
            }
            callbacks.leave()
        }
        return callbacks.wait(timeout: .now() + 3) == .success
    }
}

@Suite("PiP BT.601 conversion")
struct PictureInPictureColorConversionTests {
    @Test(
        "Local BT.601 coefficients preserve full-range neutral and primary colors",
        arguments: [
            PiPYUVTestSample(y: 16, cb: 128, cr: 128, bgra: [16, 16, 16, 255]),
            PiPYUVTestSample(y: 235, cb: 128, cr: 128, bgra: [235, 235, 235, 255]),
            PiPYUVTestSample(y: 76, cb: 85, cr: 255, bgra: [0, 0, 254, 255]),
            PiPYUVTestSample(y: 150, cb: 44, cr: 21, bgra: [1, 255, 0, 255]),
            PiPYUVTestSample(y: 29, cb: 255, cr: 107, bgra: [254, 0, 0, 255]),
        ]
    )
    func convertsKnownFullRangeSamples(sample: PiPYUVTestSample) throws {
        let fixture = I420TestFrame(
            width: 2, height: 2, y: Array(repeating: sample.y, count: 4),
            cb: [sample.cb], cr: [sample.cr])
        let buffer = try makePixelBuffer(width: 2, height: 2)
        let converter = YUVToARGBAccelerator()

        let result = fixture.withFrame { converter.convertFrameVImageYUV($0, to: buffer) }

        #expect(result == kvImageNoError)
        let pixels = try visiblePixels(in: buffer)
        for pixel in pixels {
            for channel in 0..<4 {
                #expect(abs(Int(pixel[channel]) - Int(sample.bgra[channel])) <= 2)
            }
        }
    }

    @Test("Conversion honors padded plane strides and mirrors visible pixels")
    func respectsStrideAndMirroring() throws {
        let row: [UInt8] = [32, 64, 128, 224]
        let fixture = I420TestFrame(
            width: 4, height: 2,
            y: row + [255, 255, 255, 255] + row + [255, 255, 255, 255],
            cb: [128, 128, 0, 0], cr: [128, 128, 255, 255],
            yStride: 8, chromaStride: 4)
        let converter = YUVToARGBAccelerator()
        let normal = try makePixelBuffer(width: 4, height: 2)
        let mirrored = try makePixelBuffer(width: 4, height: 2)
        let normalResult = fixture.withFrame { converter.convertFrameVImageYUV($0, to: normal) }
        let mirroredResult = fixture.withFrame { converter.convertFrameVImageYUV($0, to: mirrored, mirrored: true) }

        #expect(normalResult == kvImageNoError)
        #expect(mirroredResult == kvImageNoError)
        let normalPixels = try visiblePixels(in: normal)
        let mirroredPixels = try visiblePixels(in: mirrored)
        for y in 0..<2 {
            for x in 0..<4 {
                let normalPixel = normalPixels[y * 4 + x]
                #expect(abs(Int(normalPixel[0]) - Int(row[x])) <= 1)
                #expect(normalPixel[0] == normalPixel[1])
                #expect(normalPixel[1] == normalPixel[2])
                #expect(normalPixel[3] == 255)
                #expect(mirroredPixels[y * 4 + x] == normalPixels[y * 4 + 3 - x])
            }
        }
    }

    private func makePixelBuffer(width: Int, height: Int) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let result = CVPixelBufferCreate(
            kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &buffer)
        #expect(result == kCVReturnSuccess)
        return try #require(buffer)
    }

    private func visiblePixels(in buffer: CVPixelBuffer) throws -> [[UInt8]] {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let base = try #require(CVPixelBufferGetBaseAddress(buffer)).assumingMemoryBound(to: UInt8.self)
        let width = CVPixelBufferGetWidth(buffer)
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        return (0..<CVPixelBufferGetHeight(buffer)).flatMap { y in
            (0..<width).map { x in
                Array(UnsafeBufferPointer(start: base + y * stride + x * 4, count: 4))
            }
        }
    }
}

struct PiPYUVTestSample: Sendable {
    let y: UInt8
    let cb: UInt8
    let cr: UInt8
    let bgra: [UInt8]
}

/// Owns plane bytes until the synchronous callback finishes. SDK objects and their
/// borrowed pointers are created on the delivery thread and never cross an executor.
private struct I420TestFrame: Sendable {
    let width: Int
    let height: Int
    let y: [UInt8]
    let cb: [UInt8]
    let cr: [UInt8]
    let yStride: Int
    let chromaStride: Int

    init(
        width: Int = 2, height: Int = 2,
        y: [UInt8] = [32, 64, 128, 224], cb: [UInt8] = [128], cr: [UInt8] = [128],
        yStride: Int? = nil, chromaStride: Int? = nil
    ) {
        self.width = width
        self.height = height
        self.y = y
        self.cb = cb
        self.cr = cr
        self.yStride = yStride ?? width
        self.chromaStride = chromaStride ?? width / 2
    }

    func withFrame<Result>(_ callback: (OTVideoFrame) -> Result) -> Result {
        var y = y
        var cb = cb
        var cr = cr
        return y.withUnsafeMutableBufferPointer { yBytes in
            cb.withUnsafeMutableBufferPointer { cbBytes in
                cr.withUnsafeMutableBufferPointer { crBytes in
                    let format = OTVideoFormat()
                    format.pixelFormat = .I420
                    format.imageWidth = UInt32(width)
                    format.imageHeight = UInt32(height)
                    format.bytesPerRow = NSMutableArray(array: [yStride, chromaStride, chromaStride])
                    let planes = NSPointerArray(options: [.opaqueMemory, .opaquePersonality])
                    planes.addPointer(yBytes.baseAddress.map { UnsafeMutableRawPointer($0) })
                    planes.addPointer(cbBytes.baseAddress.map { UnsafeMutableRawPointer($0) })
                    planes.addPointer(crBytes.baseAddress.map { UnsafeMutableRawPointer($0) })
                    let frame = OTVideoFrame()
                    frame.format = format
                    frame.planes = planes
                    return callback(frame)
                }
            }
        }
    }
}
