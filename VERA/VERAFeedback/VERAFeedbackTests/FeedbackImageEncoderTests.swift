import Foundation
import Testing

@testable import VERAFeedback

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif


@Suite("Feedback Image Encoder Tests")
struct FeedbackImageEncoderTests {

    @Test("Large screenshot encodes under payload limit")
    func largeScreenshotEncodesUnderLimit() {
        #if canImport(UIKit)
            let image = makeSolidImage(size: CGSize(width: 1_170, height: 2_532))
        #elseif canImport(AppKit)
            let image = makeSolidImage(size: NSSize(width: 1_170, height: 2_532))
        #else
            return
        #endif

        let base64 = FeedbackImageEncoder.encodeToBase64(image)
        let payload = Data(base64Encoded: base64)

        #expect(!base64.isEmpty)
        #expect(payload?.count ?? Int.max <= FeedbackImageEncoder.maxPayloadBytes)
    }

    @Test("Nil image encodes to empty string")
    func nilImageEncodesToEmptyString() {
        #expect(FeedbackImageEncoder.encodeToBase64(nil) == "")
    }

    @Test("Small image encodes without exceeding payload limit")
    func smallImageEncodesWithoutExceedingLimit() {
        #if canImport(UIKit)
            let image = makeSolidImage(size: CGSize(width: 320, height: 240))
        #elseif canImport(AppKit)
            let image = makeSolidImage(size: NSSize(width: 320, height: 240))
        #else
            return
        #endif

        let base64 = FeedbackImageEncoder.encodeToBase64(image)
        let payload = Data(base64Encoded: base64)

        #expect(!base64.isEmpty)
        #expect(payload?.count ?? Int.max <= FeedbackImageEncoder.maxPayloadBytes)
    }

    #if canImport(UIKit)
        private func makeSolidImage(size: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                UIColor.systemBlue.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
    #elseif canImport(AppKit)
        private func makeSolidImage(size: NSSize) -> NSImage {
            let image = NSImage(size: size)
            image.lockFocus()
            NSColor.systemBlue.setFill()
            NSRect(origin: .zero, size: size).fill()
            image.unlockFocus()
            return image
        }
    #endif
}
