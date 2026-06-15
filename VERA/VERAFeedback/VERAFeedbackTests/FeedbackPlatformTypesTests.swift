import Foundation
import SwiftUI
import Testing

@testable import VERAFeedback

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif


@Suite("Feedback platform types tests")
struct FeedbackPlatformTypesTests {

    @Test("PlatformImageFactory decodes valid PNG data")
    func platformImageFactoryDecodesPNG() {
        #if canImport(UIKit)
            let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            }
            guard let data = image.pngData() else {
                Issue.record("Expected PNG data")
                return
            }
        #elseif canImport(AppKit)
            let image = NSImage(size: NSSize(width: 10, height: 10))
            image.lockFocus()
            NSColor.red.setFill()
            NSRect(x: 0, y: 0, width: 10, height: 10).fill()
            image.unlockFocus()
            guard let tiff = image.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiff),
                let data = bitmap.representation(using: .png, properties: [:])
            else {
                Issue.record("Expected PNG data")
                return
            }
        #else
            return
        #endif

        #expect(PlatformImageFactory.image(from: data) != nil)
        #expect(PlatformImageFactory.image(from: Data()) == nil)
    }

    @Test("SwiftUI Image can be created from platform image")
    func swiftUIImageFromPlatformImage() {
        #if canImport(UIKit)
            let platformImage = UIImage()
        #elseif canImport(AppKit)
            let platformImage = NSImage(size: NSSize(width: 1, height: 1))
        #else
            return
        #endif

        _ = Image(platformImage: platformImage)
        _ = Color.feedbackFormBackground
        #expect(true)
    }
}
