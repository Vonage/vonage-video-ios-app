//
//  Created by Vonage on 20/11/26.
//

import CoreMedia
import CoreVideo
import Darwin
import OpenTok
import Testing
import os

@testable import VERAVonageScreenSharePlugin

@Suite("In-process screen share capturer")
struct InProcessScreenShareCapturerTests {
    @Test("A ready session delivers a frame and drops a near-duplicate")
    func deliversFrameAndDropsDuplicate() throws {
        let capturer = InProcessScreenShareCapturer(retransmitInterval: .seconds(30))
        let consumer = FrameDeliverySpy()
        capturer.videoCaptureConsumer = consumer
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)
        #expect(capturer.isCaptureStarted())

        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 0))
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 1))
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 20))

        #expect(consumer.count == 2)
        #expect(capturer.videoContentHint == .text)
        capturer.videoContentHint = .none
        #expect(capturer.videoContentHint == .none)
        _ = capturer.stop()
    }

    @Test("Frames are dropped until capture and the session are both ready")
    func dropsUntilReady() throws {
        let capturer = InProcessScreenShareCapturer(retransmitInterval: .seconds(30))
        let consumer = FrameDeliverySpy()
        capturer.videoCaptureConsumer = consumer
        capturer.initCapture()
        let format = OTVideoFormat(argbWithWidth: 16, height: 16)
        #expect(capturer.captureSettings(format) == 0)
        #expect(format.pixelFormat == .ARGB)

        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 0))
        #expect(capturer.start() == 0)
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 0))
        #expect(consumer.count == 0)

        capturer.sessionDidConnect()
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 0))
        #expect(consumer.count == 1)
        _ = capturer.stop()
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 50))
        #expect(consumer.count == 1)
    }

    @Test("The last frame is sent again until capture stops")
    func retransmitsUntilStop() async throws {
        let capturer = InProcessScreenShareCapturer(retransmitInterval: .milliseconds(40))
        let consumer = FrameDeliverySpy()
        capturer.videoCaptureConsumer = consumer
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 0))

        let deadline = Date().addingTimeInterval(1)
        while consumer.count < 2, Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(consumer.count >= 2)
        _ = capturer.stop()
        let stoppedCount = consumer.count
        try await Task.sleep(nanoseconds: 80_000_000)
        #expect(consumer.count == stoppedCount)
    }

    @Test("Closing the capturer rejects later capture and clears the consumer")
    func closeRejectsLaterCapture() async throws {
        let capturer = InProcessScreenShareCapturer(retransmitInterval: .seconds(30))
        let consumer = FrameDeliverySpy()
        capturer.videoCaptureConsumer = consumer
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 0))
        #expect(consumer.count == 1)

        capturer.sessionDidDisconnect()
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 50))
        #expect(consumer.count == 1)

        capturer.releaseCapture()
        capturer.releaseCapture()
        #expect(capturer.start() == -1)
        #expect(!capturer.isCaptureStarted())
        capturer.sessionDidConnect()
        capturer.consumeVideoSampleBuffer(try makeImageSampleBuffer(timestamp: 80))
        #expect(consumer.count == 1)
        try await Task.sleep(nanoseconds: 50_000_000)
    }
}

private func makeImageSampleBuffer(timestamp: Int64) throws -> CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        64,
        32,
        kCVPixelFormatType_32BGRA,
        nil,
        &pixelBuffer)
    try #require(status == kCVReturnSuccess)
    let imageBuffer = try #require(pixelBuffer)
    CVPixelBufferLockBaseAddress(imageBuffer, [])
    if let bytes = CVPixelBufferGetBaseAddress(imageBuffer) {
        memset(bytes, 0, CVPixelBufferGetBytesPerRow(imageBuffer) * CVPixelBufferGetHeight(imageBuffer))
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, [])

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

private final class FrameDeliverySpy: NSObject, OTVideoCaptureConsumer, @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: 0)
    var count: Int { lock.withLock { $0 } }

    func consumeFrame(_ frame: OTVideoFrame) {
        lock.withLock { $0 += 1 }
    }

    func consumeImageBuffer(
        _ frame: CVImageBuffer,
        orientation: OTVideoOrientation,
        timestamp: CMTime,
        metadata: Data?
    ) -> Bool {
        false
    }
}
