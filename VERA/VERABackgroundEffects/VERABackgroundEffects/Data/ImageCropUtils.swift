//
//  Created by Vonage on 31/05/2026.
//

import CoreGraphics
import Foundation
import ImageIO

/// Center-crops an image to a portrait aspect ratio suitable for background replacement.
///
/// The target ratio defaults to 9:16 (720×1280 at HIGH resolution), matching the Android implementation.
enum ImageCropUtils {

    /// Default portrait aspect ratio (width / height) — 9:16.
    static let defaultPortraitRatio: CGFloat = 9.0 / 16.0

    /// Center-crops image data to a portrait aspect ratio and returns JPEG data.
    ///
    /// - Parameters:
    ///   - imageData: Source image data (PNG or JPEG).
    ///   - aspectRatio: Target width/height ratio. Defaults to 9:16.
    ///   - compressionQuality: JPEG compression quality (0.0–1.0).
    /// - Returns: JPEG data of the cropped image, or `nil` if the source cannot be decoded.
    static func centerCropToPortrait(
        _ imageData: Data,
        aspectRatio: CGFloat = defaultPortraitRatio,
        compressionQuality: CGFloat = 0.85
    ) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }

        let cropped = centerCropToPortrait(cgImage, aspectRatio: aspectRatio)
        return jpegData(from: cropped, quality: compressionQuality)
    }

    /// Center-crops a `CGImage` to the given portrait aspect ratio.
    static func centerCropToPortrait(
        _ image: CGImage,
        aspectRatio: CGFloat = defaultPortraitRatio
    ) -> CGImage {
        let sourceWidth = CGFloat(image.width)
        let sourceHeight = CGFloat(image.height)
        let sourceRatio = sourceWidth / sourceHeight

        if sourceRatio <= aspectRatio {
            // Source is already narrower or equal to target — crop height
            let targetHeight = sourceWidth / aspectRatio
            let yOffset = (sourceHeight - targetHeight) / 2.0
            let rect = CGRect(x: 0, y: yOffset, width: sourceWidth, height: targetHeight)
            return image.cropping(to: rect) ?? image
        } else {
            // Source is wider — crop width
            let targetWidth = sourceHeight * aspectRatio
            let xOffset = (sourceWidth - targetWidth) / 2.0
            let rect = CGRect(x: xOffset, y: 0, width: targetWidth, height: sourceHeight)
            return image.cropping(to: rect) ?? image
        }
    }

    /// Encodes a `CGImage` as JPEG data.
    static func jpegData(from image: CGImage, quality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else { return nil }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
