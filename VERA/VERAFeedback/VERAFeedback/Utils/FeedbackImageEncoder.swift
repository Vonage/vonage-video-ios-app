//
//  Created by Vonage on 11/06/2026.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum FeedbackImageEncoder {

    /// Maximum width or height before scaling down.
    static let maxDimension: CGFloat = 1_280

    /// Target maximum encoded JPEG size before Base64 (~530 KB on the wire).
    static let maxPayloadBytes = 400_000

    static let initialJPEGQuality: CGFloat = 0.75
    static let minimumJPEGQuality: CGFloat = 0.4
    static let minimumDimension: CGFloat = 480

    /// Encodes a screenshot for the feedback API as a Base64 JPEG string.
    static func encodeToBase64(_ image: PlatformImage?) -> String {
        guard let image, let data = compressedJPEGData(from: image) else { return "" }
        return data.base64EncodedString()
    }

    private static func compressedJPEGData(from image: PlatformImage) -> Data? {
        var resized = resize(image, maxDimension: maxDimension)
        var quality = initialJPEGQuality

        while quality >= minimumJPEGQuality {
            if let data = jpegData(from: resized, quality: quality), data.count <= maxPayloadBytes {
                return data
            }
            quality -= 0.1
        }

        var dimension = maxDimension * 0.75
        while dimension >= minimumDimension {
            resized = resize(image, maxDimension: dimension)
            if let data = jpegData(from: resized, quality: minimumJPEGQuality),
                data.count <= maxPayloadBytes
            {
                return data
            }
            dimension *= 0.75
        }

        return jpegData(from: resized, quality: minimumJPEGQuality)
    }

    #if canImport(UIKit)
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private static func jpegData(from image: UIImage, quality: CGFloat) -> Data? {
        image.jpegData(compressionQuality: quality)
    }

    #elseif canImport(AppKit)
    private static func resize(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let targetSize = NSSize(width: size.width * scale, height: size.height * scale)
        let targetImage = NSImage(size: targetSize)
        targetImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1
        )
        targetImage.unlockFocus()
        return targetImage
    }

    private static func jpegData(from image: NSImage, quality: CGFloat) -> Data? {
        guard let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }

        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
    }
    #endif
}
