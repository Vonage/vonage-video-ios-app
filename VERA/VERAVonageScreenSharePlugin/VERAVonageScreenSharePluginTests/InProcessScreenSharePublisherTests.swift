//
//  Created by Vonage on 20/11/26.
//

import CoreMedia
import CoreVideo
import Darwin
import OpenTok
import Testing
import VERAScreenShare

@testable import VERAVonageScreenSharePlugin

@Suite("In-process screen share publisher", .serialized)
struct InProcessScreenSharePublisherTests {
    @Test("Starting with a fake session covers connect, publish, and stop")
    func startPublishAndStop() async throws {
        let publisher = makePublisher(username: "Ada")
        publisher.captureWillStart()
        let session = try #require(
            OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil))
        publisher.sessionDidConnect(session)
        publisher.sessionDidDisconnect(session)
        publisher.consume(sampleBuffer: try makeImageSampleBuffer(timestamp: 0))

        let error = OTError(domain: OT_SESSION_ERROR_DOMAIN, code: 1006, userInfo: nil)
        publisher.session(session, didFailWithError: error)
        publisher.session(session, streamCreated: OTStream())
        publisher.session(session, streamDestroyed: OTStream())
        if let kit = OTPublisherKit(delegate: publisher, settings: OTPublisherSettings()) {
            publisher.publisher(kit, streamCreated: OTStream())
            publisher.publisher(kit, streamDestroyed: OTStream())
            publisher.publisher(kit, didFailWithError: error)
        }
        await flushMain()
        publisher.captureDidStop()
        publisher.captureDidStop()
    }

    @Test("An empty publisher name is left unset")
    func emptyNameStillStops() async {
        let publisher = makePublisher(username: "")
        publisher.captureWillStart()
        publisher.captureDidStop()
        await flushMain()
    }

    private func makePublisher(username: String) -> InProcessScreenSharePublisher {
        InProcessScreenSharePublisher(
            credentials: ScreenShareCredentials(
                applicationId: "applicationId",
                sessionId: "sessionId",
                token: "token",
                username: username))
    }
}

private func flushMain() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async { continuation.resume() }
    }
}

private func makeImageSampleBuffer(timestamp: Int64) throws -> CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        16,
        16,
        kCVPixelFormatType_32BGRA,
        nil,
        &pixelBuffer)
    try #require(status == kCVReturnSuccess)
    let imageBuffer = try #require(pixelBuffer)
    var format: CMVideoFormatDescription?
    try #require(
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            formatDescriptionOut: &format) == noErr)
    let formatDescription = try #require(format)
    var timing = CMSampleTimingInfo(
        duration: .invalid,
        presentationTimeStamp: CMTime(value: timestamp, timescale: 1_000),
        decodeTimeStamp: .invalid)
    var sampleBuffer: CMSampleBuffer?
    try #require(
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer) == noErr)
    return try #require(sampleBuffer)
}
