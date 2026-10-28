//
//  Created by Vonage on 15/10/2026.
//

import CoreMedia
import CoreVideo
import Foundation
import OpenTok
import Testing

@Suite("Broadcast capture ownership")
struct ScreenShareVideoCapturerTests {
    @Test("Finish closes the capture gate permanently despite late SDK callbacks")
    func finishRejectsLateRestart() {
        let capturer = ScreenShareVideoCapturer()
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)
        #expect(capturer.isCaptureStarted())

        capturer.close()
        capturer.sessionDidConnect()
        capturer.setPaused(false)

        #expect(capturer.isClosed)
        #expect(!capturer.isCaptureStarted())
        #expect(capturer.start() == -1)
    }

    @Test("Ordinary stop permits a later restart while final release does not")
    func stopAndReleaseHaveDistinctLifetimes() {
        let capturer = ScreenShareVideoCapturer()
        #expect(capturer.start() == 0)
        #expect(capturer.stop() == 0)
        #expect(!capturer.isCaptureStarted())
        #expect(!capturer.isClosed)
        #expect(capturer.start() == 0)

        capturer.releaseCapture()
        #expect(capturer.isClosed)
        #expect(capturer.videoCaptureConsumer == nil)
        #expect(capturer.start() == -1)
    }

    @Test("Pause and finish reject video samples without moving borrowed buffers to another queue")
    func sampleDeliveryRespectsPauseAndFinish() throws {
        let capturer = ScreenShareVideoCapturer()
        let consumer = FrameConsumerSpy()
        capturer.videoCaptureConsumer = consumer
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)

        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 1_000))
        #expect(consumer.frameCount == 1)

        capturer.setPaused(true)
        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 2_000))
        #expect(consumer.frameCount == 1)

        capturer.setPaused(false)
        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 3_000))
        #expect(consumer.frameCount == 2)

        capturer.close()
        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 4_000))
        #expect(consumer.frameCount == 2)
    }

    @Test("Static-frame retransmission pauses and cannot deliver after finish")
    func retransmissionStopsAfterFinish() async throws {
        let capturer = ScreenShareVideoCapturer()
        defer { capturer.close() }
        let consumer = FrameConsumerSpy()
        capturer.videoCaptureConsumer = consumer
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)
        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 1_000))
        #expect(consumer.frameCount == 1)

        capturer.setPaused(true)
        try await Task.sleep(nanoseconds: 350_000_000)
        #expect(consumer.frameCount == 1)
        capturer.setPaused(false)
        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 2_000))
        #expect(consumer.frameCount == 2)

        let retransmitted = await waitFor(consumer.deliveries) { $0 >= 3 }
        #expect(retransmitted, "Expected one static-frame retransmission within the timeout")

        await withCheckedContinuation { continuation in
            capturer.close(on: .global()) { continuation.resume() }
        }
        let countAfterFinish = consumer.frameCount
        try await Task.sleep(nanoseconds: 600_000_000)
        #expect(consumer.frameCount == countAfterFinish)
    }

    @Test("Canceled timer callbacks cannot retransmit a frame owned by a newer generation")
    func staleTimerGenerationCannotOvertakeFreshFrame() throws {
        let capturer = ScreenShareVideoCapturer(retransmitInterval: .seconds(60))
        defer { capturer.close() }
        let consumer = FrameConsumerSpy()
        capturer.videoCaptureConsumer = consumer
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)
        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 1_000))
        let staleGeneration = capturer.retransmissionGeneration
        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 2_000))
        let currentGeneration = capturer.retransmissionGeneration
        #expect(currentGeneration != staleGeneration)
        #expect(consumer.frameCount == 2)

        capturer.retransmitLastFrame(expectedGeneration: staleGeneration)
        #expect(consumer.frameCount == 2)
        capturer.retransmitLastFrame(expectedGeneration: currentGeneration)
        #expect(consumer.frameCount == 3)
        capturer.retransmitLastFrame(expectedGeneration: currentGeneration)
        #expect(consumer.frameCount == 3)
    }

    @Test("A consumer may reenter capture control on another thread without blocking its delivery")
    func consumerReentryDoesNotHoldControlLock() throws {
        let capturer = ScreenShareVideoCapturer(retransmitInterval: .seconds(60))
        let controlReturned = LockedCaptureResult()
        let didReturn = DispatchSemaphore(value: 0)
        let consumer = FrameConsumerSpy(onRelease: {}) { [weak capturer] count in
            guard count == 1, let capturer else { return }
            // A reentrant frame must drop instead of mutating the in-flight output buffer.
            if let sample = try? makeSampleBuffer(timestamp: 2_000) {
                capturer.consumeVideoSampleBuffer(sample)
            }
            DispatchQueue.global().async {
                _ = capturer.stop()
                capturer.releaseCapture()
                didReturn.signal()
            }
            controlReturned.value = didReturn.wait(timeout: .now() + 2) == .success
        }
        capturer.videoCaptureConsumer = consumer
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)
        capturer.consumeVideoSampleBuffer(try makeSampleBuffer(timestamp: 1_000))

        #expect(controlReturned.value)
        #expect(consumer.frameCount == 1)
        #expect(capturer.isClosed)
    }

    @Test("Releasing a replaced SDK consumer also happens outside the control lock")
    func consumerReleaseMayReenterControl() {
        let capturer = ScreenShareVideoCapturer(retransmitInterval: .seconds(60))
        let controlReturned = LockedCaptureResult()
        let didReturn = DispatchSemaphore(value: 0)
        var consumer: FrameConsumerSpy? = FrameConsumerSpy(
            onRelease: { [weak capturer] in
                DispatchQueue.global().async { [weak capturer] in
                    _ = capturer?.stop()
                    didReturn.signal()
                }
                controlReturned.value = didReturn.wait(timeout: .now() + 2) == .success
            })
        capturer.videoCaptureConsumer = consumer
        consumer = nil
        capturer.videoCaptureConsumer = nil

        #expect(controlReturned.value)
    }

    @Test("Finish joins an admitted consumer asynchronously before allowing teardown")
    func finishWaitsForInFlightDeliveryWithoutBlockingControl() async throws {
        let capturer = ScreenShareVideoCapturer(retransmitInterval: .seconds(60))
        let releaseConsumer = DispatchSemaphore(value: 0)
        defer { releaseConsumer.signal() }
        let consumer = FrameConsumerSpy(onRelease: {}) { count in
            if count == 1 {
                _ = releaseConsumer.wait(timeout: .now() + 5)
            }
        }
        capturer.videoCaptureConsumer = consumer
        capturer.sessionDidConnect()
        #expect(capturer.start() == 0)
        let delivery = Task.detached {
            let sample = try makeSampleBuffer(timestamp: 1_000)
            capturer.consumeVideoSampleBuffer(sample)
        }
        let entered = await waitFor(consumer.deliveries) { $0 == 1 }
        #expect(entered)

        let completion = AsyncStream<Void>.makeStream()
        let didFinish = LockedCaptureResult()
        capturer.close(on: .global()) {
            didFinish.value = true
            completion.continuation.yield(())
        }
        #expect(capturer.isClosed)
        #expect(!didFinish.value)
        #expect(capturer.start() == -1)

        releaseConsumer.signal()
        try await delivery.value
        let completed = await waitFor(completion.stream) { _ in true }
        #expect(completed)
        #expect(didFinish.value)
        #expect(consumer.frameCount == 1)
    }

    @Test("Overlapping lifecycle callbacks cannot reopen a finished capture")
    func overlappingControlEventsRespectFinish() async {
        let capturer = ScreenShareVideoCapturer()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<48 {
                group.addTask {
                    if index.isMultiple(of: 3) {
                        capturer.sessionDidConnect()
                        _ = capturer.start()
                    } else if index.isMultiple(of: 2) {
                        capturer.setPaused(true)
                        _ = capturer.stop()
                        capturer.sessionDidDisconnect()
                    } else {
                        capturer.close()
                        capturer.setPaused(false)
                    }
                }
            }
        }

        #expect(capturer.isClosed)
        #expect(!capturer.isCaptureStarted())
        #expect(capturer.start() == -1)
    }
}

private func makeSampleBuffer(timestamp: Int64) throws -> CMSampleBuffer {
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

// Only copied counts leave the callback. The SDK-owned video frame never escapes it.
private final class FrameConsumerSpy: NSObject, OTVideoCaptureConsumer, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    let deliveries: AsyncStream<Int>
    private let continuation: AsyncStream<Int>.Continuation
    private let onFrame: @Sendable (Int) -> Void
    private let onRelease: @Sendable () -> Void

    init(
        onRelease: @escaping @Sendable () -> Void = {},
        onFrame: @escaping @Sendable (Int) -> Void = { _ in }
    ) {
        let pair = AsyncStream<Int>.makeStream()
        deliveries = pair.stream
        continuation = pair.continuation
        self.onFrame = onFrame
        self.onRelease = onRelease
        super.init()
    }

    deinit { onRelease() }

    var frameCount: Int { lock.withLock { count } }

    func consumeFrame(_ frame: OTVideoFrame) {
        let next = lock.withLock {
            count += 1
            return count
        }
        continuation.yield(next)
        onFrame(next)
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

private final class LockedCaptureResult: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue = false
    var value: Bool {
        get { lock.withLock { storedValue } }
        set { lock.withLock { storedValue = newValue } }
    }
}

private func waitFor<Value: Sendable>(
    _ events: AsyncStream<Value>,
    matching predicate: @escaping @Sendable (Value) -> Bool
) async -> Bool {
    await withTaskGroup(of: Bool.self) { group in
        group.addTask {
            for await event in events {
                if predicate(event) { return true }
            }
            return false
        }
        group.addTask {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return false
        }
        let result = await group.next() ?? false
        group.cancelAll()
        return result
    }
}
