//
//  Created by Vonage on 31/05/2026.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import VERADomain

@testable import VERABackgroundEffects

@Suite("ImageCropUtils tests")
struct ImageCropUtilsTests {

    @Test("centerCropToPortrait returns data for valid JPEG input")
    func centerCropToPortraitReturnsDataForValidInput() throws {
        let imageData = makeTestJPEGData(width: 1920, height: 1080)
        let result = try ImageCropUtils.centerCropToPortrait(imageData)

        #expect(!result.isEmpty)
    }

    @Test("centerCropToPortrait throws for invalid data")
    func centerCropToPortraitThrowsForInvalidData() throws {
        #expect(throws: ImageCropUtilsError.imageDecodingFailed) {
            try ImageCropUtils.centerCropToPortrait(Data([0x00, 0x01, 0x02]))
        }
    }

    @Test("centerCropToPortrait handles already portrait image")
    func centerCropToPortraitHandlesAlreadyPortraitImage() throws {
        let imageData = makeTestJPEGData(width: 720, height: 1280)
        let result = try ImageCropUtils.centerCropToPortrait(imageData)

        #expect(!result.isEmpty)
    }

    @Test("centerCropToPortrait produces portrait aspect ratio")
    func centerCropToPortraitProducesPortraitAspectRatio() throws {
        let imageData = makeTestJPEGData(width: 1920, height: 1080)
        let croppedData = try ImageCropUtils.centerCropToPortrait(imageData)

        guard let source = CGImageSourceCreateWithData(croppedData as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
            let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
            let height = properties[kCGImagePropertyPixelHeight as String] as? Int
        else {
            Issue.record("Could not read cropped image properties")
            return
        }

        // Height should be greater than width (portrait)
        #expect(height > width)
    }

    // MARK: - Helpers

    private func makeTestJPEGData(width: Int, height: Int) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let ctx = CGContext(
                data: nil, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            let cgImage = ctx.makeImage()
        else {
            return Data()
        }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil)
        else {
            return Data()
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
        return data as Data
    }
}
