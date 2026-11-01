//
//  Created by Vonage on 1/11/26.
//

import CoreImage
import CoreVideo
import Testing
import UIKit

@testable import VERAVonage

@Suite("Dual capture")
struct DualCaptureTests {
    @Test("Portrait and landscape map to upright connection angles")
    func rotationAngles() {
        #expect(DualCaptureRotation.angle(for: .portrait) == 90)
        #expect(DualCaptureRotation.angle(for: .portraitUpsideDown) == 270)
        #expect(DualCaptureRotation.angle(for: .landscapeLeft) == 180)
        #expect(DualCaptureRotation.angle(for: .landscapeRight) == 0)
        #expect(DualCaptureRotation.angle(for: .faceUp) == nil)
    }

    @Test("Output dimensions stay codec-aligned and within the long-edge cap")
    func outputSizeIsAligned() {
        let fitted = DualCaptureCompositor.outputSize(width: 1000, height: 500)
        #expect(fitted.width == 1008)
        #expect(fitted.height == 512)
        #expect(fitted.width.isMultiple(of: 16))
        #expect(fitted.height.isMultiple(of: 16))

        let capped = DualCaptureCompositor.outputSize(width: 2000, height: 1000)
        #expect(capped.width == 1280)
        #expect(capped.height == 640)
    }

    @Test("The front window sits at the top right, below the top clearance")
    func windowSitsAtTheTopRight() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 200)
        let rect = DualCaptureCompositor.windowRect(in: bounds)
        let shortSide: CGFloat = 100
        #expect(abs(rect.width - shortSide * 0.28) < 0.01)
        #expect(abs(rect.maxX - (bounds.maxX - shortSide * 0.04)) < 0.01)
        #expect(abs(rect.maxY - (bounds.maxY - bounds.height * 0.12)) < 0.01)
    }

    @Test("The rear camera fills the frame and the front camera occupies the top-right window")
    func compositePlacesFrontCameraInTheTopRight() throws {
        let rear = try makeBuffer(width: 32, height: 32, red: 255, green: 0, blue: 0)
        let front = try makeBuffer(width: 8, height: 8, red: 0, green: 0, blue: 255)
        let output = try makeBuffer(width: 32, height: 32, red: 0, green: 0, blue: 0)
        let context = CIContext(options: [.useSoftwareRenderer: true])
        DualCaptureCompositor.render(
            rear: rear,
            front: front,
            into: output,
            showsFront: true,
            layout: DualCaptureFrameLayout(
                insetWidthFraction: 0.5, marginFraction: 0, topClearanceFraction: 0, borderWidth: 0),
            context: context
        )

        let topRight = try pixel(in: output, x: 24, y: 4)
        let bottomRight = try pixel(in: output, x: 24, y: 24)
        #expect(topRight.blue > 200)
        #expect(topRight.red < 40)
        #expect(bottomRight.red > 200)
        #expect(bottomRight.blue < 40)
    }

    @Test("Hiding the front buffer leaves the rear color in that corner")
    func compositeCanOmitTheFrontCamera() throws {
        let rear = try makeBuffer(width: 32, height: 32, red: 255, green: 0, blue: 0)
        let output = try makeBuffer(width: 32, height: 32, red: 0, green: 0, blue: 0)
        let context = CIContext(options: [.useSoftwareRenderer: true])
        DualCaptureCompositor.render(
            rear: rear,
            front: nil,
            into: output,
            showsFront: false,
            context: context
        )
        let bottomRight = try pixel(in: output, x: 24, y: 24)
        #expect(bottomRight.red > 200)
        #expect(bottomRight.blue < 40)
    }

    private func makeBuffer(width: Int, height: Int, red: UInt8, green: UInt8, blue: UInt8) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            nil,
            &buffer
        )
        guard status == kCVReturnSuccess, let buffer else {
            throw DualCaptureTestError.buffer
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { throw DualCaptureTestError.buffer }
        let bytes = base.assumingMemoryBound(to: UInt8.self)
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * rowBytes + x * 4
                bytes[offset] = blue
                bytes[offset + 1] = green
                bytes[offset + 2] = red
                bytes[offset + 3] = 255
            }
        }
        return buffer
    }

    private func pixel(in buffer: CVPixelBuffer, x: Int, y: Int) throws -> (red: UInt8, green: UInt8, blue: UInt8) {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { throw DualCaptureTestError.buffer }
        let bytes = base.assumingMemoryBound(to: UInt8.self)
        let offset = y * CVPixelBufferGetBytesPerRow(buffer) + x * 4
        return (bytes[offset + 2], bytes[offset + 1], bytes[offset])
    }
}

private enum DualCaptureTestError: Error {
    case buffer
}
