import Foundation
import Testing

@testable import VERAFeedback

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

@MainActor
@Suite("Feedback screenshot worker ownership")
struct FeedbackImageBackgroundEncodingTests {
    @Test("Upload compression executes outside the UI thread and preserves the encoded image")
    func executesEncoderOffUIThread() async throws {
        let image = FeedbackTestHelpers.makeTestImage(size: .init(width: 320, height: 180))
        let expected = FeedbackImageEncoder.encodeToBase64(image)

        let actual = await FeedbackImageEncoder.encodeForUpload(image) { workerImage in
            #expect(!Thread.isMainThread)
            return FeedbackImageEncoder.encodeToBase64(workerImage)
        }

        let actualData = try #require(Data(base64Encoded: actual))
        #expect(!actualData.isEmpty)
        #expect(actualData.count <= FeedbackImageEncoder.maxPayloadBytes)
        #if canImport(UIKit)
            // The same UIImage and exact encoder preserve JPEG output and orientation handling.
            #expect(actual == expected)
        #elseif canImport(AppKit)
            let decoded = try #require(NSImage(data: actualData))
            let expectedData = try #require(Data(base64Encoded: expected))
            let expectedImage = try #require(NSImage(data: expectedData))
            #expect(decoded.size == expectedImage.size)
        #endif
    }

    @Test("Missing attachments skip compression")
    func missingImageSkipsWorker() async {
        let result = await FeedbackImageEncoder.encodeForUpload(nil) { _ in
            Issue.record("Missing attachments must not invoke the encoder")
            return "unexpected"
        }
        #expect(result.isEmpty)
    }

    #if canImport(UIKit)
        @Test("Worker preserves existing orientation and resize behavior")
        func preservesOrientedImageBehavior() async throws {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let source = UIGraphicsImageRenderer(size: .init(width: 1_600, height: 900), format: format).image {
                context in
                UIColor.red.setFill()
                context.fill(.init(x: 0, y: 0, width: 800, height: 900))
                UIColor.blue.setFill()
                context.fill(.init(x: 800, y: 0, width: 800, height: 900))
            }
            let cgImage = try #require(source.cgImage)
            let oriented = UIImage(cgImage: cgImage, scale: source.scale, orientation: .right)
            let expected = FeedbackImageEncoder.encodeToBase64(oriented)

            let actual = await FeedbackImageEncoder.encodeForUpload(oriented)

            #expect(actual == expected)
            let data = try #require(Data(base64Encoded: actual))
            let decoded = try #require(UIImage(data: data))
            #expect(max(decoded.size.width, decoded.size.height) <= FeedbackImageEncoder.maxDimension)
            let expectedData = try #require(Data(base64Encoded: expected))
            let expectedImage = try #require(UIImage(data: expectedData))
            #expect(decoded.size == expectedImage.size)
        }
    #endif
}
