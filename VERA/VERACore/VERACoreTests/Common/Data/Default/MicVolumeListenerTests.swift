//
//  Created by Vonage on 20/10/26.
//

import AVFoundation
import Combine
import Testing
import VERATestHelpers

@testable import VERACore

@MainActor
@Suite("Microphone recording ownership", .timeLimit(.minutes(1)))
struct MicVolumeListenerTests {
    @Test("Repeated start shares one tap and stop completes all observers once")
    func repeatedStartSharesRecording() async throws {
        let engine = MicrophoneAudioEngineSpy()
        let sut = makeSUT(engine: engine)
        var first: [Float] = []
        var second: [Float] = []
        var completions = 0
        let received = AsyncStream<Void>.makeStream()
        var iterator = received.stream.makeAsyncIterator()
        let one = sut.start(samplingInterval: 0.001).sink(
            receiveCompletion: { _ in
                completions += 1
                received.continuation.yield(())
            },
            receiveValue: {
                first.append($0)
                received.continuation.yield(())
            })
        let two = sut.start(samplingInterval: 0.001).sink(
            receiveCompletion: { _ in
                completions += 1
                received.continuation.yield(())
            },
            receiveValue: {
                second.append($0)
                received.continuation.yield(())
            })

        try engine.emit([0.03, -0.03])
        _ = await iterator.next()
        _ = await iterator.next()
        #expect(first == second)
        #expect(abs((first.first ?? 0) - 0.3) < 0.0001)
        #expect(engine.actions == ["install", "start"])

        sut.stop()
        sut.stop()
        _ = await iterator.next()
        _ = await iterator.next()
        #expect(completions == 2)
        #expect(engine.actions == ["install", "start", "remove", "stop"])
        withExtendedLifetime((one, two)) {}
    }

    @Test("Old tap cannot emit into a restarted recording")
    func lateCallbackCannotReachNextRecording() async throws {
        let engine = MicrophoneAudioEngineSpy()
        let sut = makeSUT(engine: engine)
        var oldValues: [Float] = []
        let oldObservation = sut.start(samplingInterval: 0.001).sink { oldValues.append($0) }
        let oldTap = try #require(engine.tap)
        sut.stop()

        var newValues: [Float] = []
        let received = AsyncStream<Void>.makeStream()
        var iterator = received.stream.makeAsyncIterator()
        let newObservation = sut.start(samplingInterval: 0.001).sink {
            newValues.append($0)
            received.continuation.yield(())
        }
        let buffer = try engine.buffer([0.08])
        oldTap(buffer)
        #expect(oldValues.isEmpty)
        #expect(newValues.isEmpty)

        try engine.emit([0.02])
        _ = await iterator.next()
        #expect(abs((newValues.first ?? 0) - 0.2) < 0.0001)
        #expect(oldValues.isEmpty)
        sut.stop()
        withExtendedLifetime((oldObservation, newObservation)) {}
    }

    @Test("Audio levels use root mean square and clamp amplified values")
    func normalizesAudioSamples() async throws {
        let engine = MicrophoneAudioEngineSpy()
        let sut = makeSUT(engine: engine)
        var levels: [Float] = []
        let received = AsyncStream<Void>.makeStream()
        var iterator = received.stream.makeAsyncIterator()
        let observation = sut.start(samplingInterval: 0.001).sink {
            levels.append($0)
            received.continuation.yield(())
        }
        for samples: [Float] in [[0, 0], [0.03, -0.04], [0.5, -0.5], []] {
            try engine.emit(samples)
            _ = await iterator.next()
        }
        #expect(levels.count == 4)
        #expect(levels.first == 0)
        #expect(abs((levels.dropFirst().first ?? 0) - sqrt(0.00125) * 10) < 0.0001)
        #expect(Array(levels.suffix(2)) == [1, 0])
        sut.stop()
        withExtendedLifetime(observation) {}
    }

    @Test("Non-floating-point audio buffers produce silence")
    func unsupportedBufferProducesSilence() async throws {
        let engine = MicrophoneAudioEngineSpy()
        let sut = makeSUT(engine: engine)
        var levels: [Float] = []
        let received = AsyncStream<Void>.makeStream()
        var iterator = received.stream.makeAsyncIterator()
        let observation = sut.start(samplingInterval: 0.001).sink {
            levels.append($0)
            received.continuation.yield(())
        }
        let format = try #require(
            AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 48_000, channels: 1, interleaved: false))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1))
        buffer.frameLength = 1
        engine.tap?(buffer)
        _ = await iterator.next()
        #expect(levels == [0])
        sut.stop()
        withExtendedLifetime(observation) {}
    }

    @Test("Unavailable microphone format does not install or start a tap")
    func unavailableMicrophoneDoesNotStartRecording() {
        let engine = MicrophoneAudioEngineSpy()
        engine.inputFormat = AVAudioFormat()
        let sut = makeSUT(engine: engine)
        let observation = sut.start().sink { _ in Issue.record("Invalid input emitted audio") }
        sut.stop()
        #expect(engine.actions.isEmpty)
        withExtendedLifetime(observation) {}
    }

    @Test("A failed engine start still removes the installed tap on stop and permits retry")
    func failedStartCanBeStoppedAndRetried() {
        let engine = MicrophoneAudioEngineSpy()
        engine.shouldFailStart = true
        let sut = makeSUT(engine: engine)
        let first = sut.start().sink { _ in }
        sut.stop()
        engine.shouldFailStart = false
        let second = sut.start().sink { _ in }
        #expect(engine.actions == ["install", "start", "remove", "stop", "install", "start"])
        sut.stop()
        withExtendedLifetime((first, second)) {}
    }

    @Test("The waiting-room decorator releases without retaining its wrapped publisher")
    func decoratorReleasesWrappedPublisher() throws {
        var wrapped: MockVERAPublisher? = MockVERAPublisher()
        weak var observedWrapped = wrapped
        var decorator: MicLevelPublisherDecorator? = MicLevelPublisherDecorator(wrapping: try #require(wrapped))
        weak var observedDecorator = decorator
        decorator?.publishAudio = false
        #expect(wrapped?.publishAudio == false)
        wrapped = nil
        #expect(observedWrapped != nil)

        decorator = nil

        #expect(observedDecorator == nil)
        #expect(observedWrapped == nil)
    }

    private func makeSUT(engine: MicrophoneAudioEngineSpy) -> MicVolumeListener {
        MicVolumeListener(audioEngine: engine)
    }
}

@MainActor
private final class MicrophoneAudioEngineSpy: MicrophoneAudioEngine {
    var inputFormat = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    var tap: (@Sendable (AVAudioPCMBuffer) -> Void)?
    var actions: [String] = []
    var shouldFailStart = false

    func installTap(format: AVAudioFormat, handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void) {
        actions.append("install")
        tap = handler
    }

    func removeTap() {
        actions.append("remove")
        tap = nil
    }

    func start() throws {
        actions.append("start")
        if shouldFailStart { throw StartError.unavailable }
    }

    func stop() { actions.append("stop") }

    func emit(_ samples: [Float]) throws {
        tap?(try buffer(samples))
    }

    func buffer(_ samples: [Float]) throws -> AVAudioPCMBuffer {
        let buffer = try #require(
            AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(max(samples.count, 1))))
        buffer.frameLength = AVAudioFrameCount(samples.count)
        let channel = try #require(buffer.floatChannelData?[0])
        for (index, sample) in samples.enumerated() { channel[index] = sample }
        return buffer
    }

    private enum StartError: Error { case unavailable }
}
