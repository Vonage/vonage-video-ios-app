//
//  MockSpeakerTestServiceTests.swift
//  VERAAudioDiagnosticsTests
//
//  Created by Vonage on 15/07/26.
//

import Combine
import Testing

@testable import VERAAudioDiagnostics

@Suite("MockSpeakerTestService tests")
struct MockSpeakerTestServiceTests {

    // MARK: - Initialization Tests

    @Test("can be initialized")
    func canBeInitialized() {
        let sut = MockSpeakerTestService()
        #expect(sut.audioLevelPublisher is AnyPublisher<Float, Never>)
    }

    // MARK: - playTestSound Tests

    @Test("playTestSound increments call count")
    func playTestSoundIncrementsCallCount() {
        let sut = MockSpeakerTestService()

        #expect(sut.playTestSoundCallCount == 0)

        sut.playTestSound()
        #expect(sut.playTestSoundCallCount == 1)

        sut.playTestSound()
        #expect(sut.playTestSoundCallCount == 2)
    }

    @Test("multiple calls to playTestSound increment correctly")
    func multiplePlayTestSoundCalls() {
        let sut = MockSpeakerTestService()

        for i in 0..<10 {
            sut.playTestSound()
            #expect(sut.playTestSoundCallCount == i + 1)
        }
    }

    // MARK: - stopTestSound Tests

    @Test("stopTestSound increments call count")
    func stopTestSoundIncrementsCallCount() {
        let sut = MockSpeakerTestService()

        #expect(sut.stopTestSoundCallCount == 0)

        sut.stopTestSound()
        #expect(sut.stopTestSoundCallCount == 1)

        sut.stopTestSound()
        #expect(sut.stopTestSoundCallCount == 2)
    }

    @Test("stopTestSound emits zero audio level")
    func stopTestSoundEmitsZeroLevel() async throws {
        let sut = MockSpeakerTestService()
        var receivedLevels: [Float] = []

        let cancellable = sut.audioLevelPublisher.sink { level in
            receivedLevels.append(level)
        }

        sut.stopTestSound()
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(receivedLevels.count == 1)
        #expect(receivedLevels[0] == 0.0)

        cancellable.cancel()
    }

    @Test("stopTestSound emits zero level multiple times")
    func stopTestSoundEmitsZeroLevelMultipleTimes() async throws {
        let sut = MockSpeakerTestService()
        var receivedLevels: [Float] = []

        let cancellable = sut.audioLevelPublisher.sink { level in
            receivedLevels.append(level)
        }

        sut.stopTestSound()
        sut.stopTestSound()
        sut.stopTestSound()
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(receivedLevels.count == 3)
        for level in receivedLevels {
            #expect(level == 0.0)
        }

        cancellable.cancel()
    }

    // MARK: - startObservingAudioRoutes Tests

    @Test("startObservingAudioRoutes increments call count")
    func startObservingAudioRoutesIncrementsCallCount() {
        let sut = MockSpeakerTestService()

        #expect(sut.startObservingAudioRoutesCallCount == 0)

        sut.startObservingAudioRoutes()
        #expect(sut.startObservingAudioRoutesCallCount == 1)

        sut.startObservingAudioRoutes()
        #expect(sut.startObservingAudioRoutesCallCount == 2)
    }

    @Test("startObservingAudioRoutes can be called repeatedly")
    func startObservingAudioRoutesRepeatedCalls() {
        let sut = MockSpeakerTestService()

        for i in 0..<5 {
            sut.startObservingAudioRoutes()
            #expect(sut.startObservingAudioRoutesCallCount == i + 1)
        }
    }

    @Test("startObservingAudioRoutes does not emit audio levels")
    func startObservingAudioRoutesNoAudioEmission() async throws {
        let sut = MockSpeakerTestService()
        var receivedLevels: [Float] = []

        let cancellable = sut.audioLevelPublisher.sink { level in
            receivedLevels.append(level)
        }

        sut.startObservingAudioRoutes()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(receivedLevels.isEmpty)

        cancellable.cancel()
    }

    // MARK: - stopObservingAudioRoutes Tests

    @Test("stopObservingAudioRoutes increments call count")
    func stopObservingAudioRoutesIncrementsCallCount() {
        let sut = MockSpeakerTestService()

        #expect(sut.stopObservingAudioRoutesCallCount == 0)

        sut.stopObservingAudioRoutes()
        #expect(sut.stopObservingAudioRoutesCallCount == 1)

        sut.stopObservingAudioRoutes()
        #expect(sut.stopObservingAudioRoutesCallCount == 2)
    }

    @Test("stopObservingAudioRoutes can be called repeatedly")
    func stopObservingAudioRoutesRepeatedCalls() {
        let sut = MockSpeakerTestService()

        for i in 0..<5 {
            sut.stopObservingAudioRoutes()
            #expect(sut.stopObservingAudioRoutesCallCount == i + 1)
        }
    }

    @Test("stopObservingAudioRoutes does not emit audio levels")
    func stopObservingAudioRoutesNoAudioEmission() async throws {
        let sut = MockSpeakerTestService()
        var receivedLevels: [Float] = []

        let cancellable = sut.audioLevelPublisher.sink { level in
            receivedLevels.append(level)
        }

        sut.stopObservingAudioRoutes()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(receivedLevels.isEmpty)

        cancellable.cancel()
    }

    // MARK: - Call Sequence Tests

    @Test("startObservingAudioRoutes and stopObservingAudioRoutes sequence")
    func observingRoutesSequence() {
        let sut = MockSpeakerTestService()

        sut.startObservingAudioRoutes()
        #expect(sut.startObservingAudioRoutesCallCount == 1)
        #expect(sut.stopObservingAudioRoutesCallCount == 0)

        sut.stopObservingAudioRoutes()
        #expect(sut.startObservingAudioRoutesCallCount == 1)
        #expect(sut.stopObservingAudioRoutesCallCount == 1)

        sut.startObservingAudioRoutes()
        #expect(sut.startObservingAudioRoutesCallCount == 2)
        #expect(sut.stopObservingAudioRoutesCallCount == 1)
    }

    @Test("all methods track call counts independently")
    func allMethodsTrackCountersIndependently() {
        let sut = MockSpeakerTestService()

        sut.playTestSound()
        sut.playTestSound()
        sut.stopTestSound()
        sut.startObservingAudioRoutes()
        sut.stopObservingAudioRoutes()

        #expect(sut.playTestSoundCallCount == 2)
        #expect(sut.stopTestSoundCallCount == 1)
        #expect(sut.startObservingAudioRoutesCallCount == 1)
        #expect(sut.stopObservingAudioRoutesCallCount == 1)
    }

    // MARK: - emitAudioLevel Tests

    @Test("emitAudioLevel publishes values")
    func emitAudioLevelPublishesValues() async throws {
        let sut = MockSpeakerTestService()
        var receivedLevels: [Float] = []

        let cancellable = sut.audioLevelPublisher.sink { level in
            receivedLevels.append(level)
        }

        sut.emitAudioLevel(0.5)
        sut.emitAudioLevel(0.75)
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(receivedLevels.count == 2)
        #expect(receivedLevels[0] == 0.5)
        #expect(receivedLevels[1] == 0.75)

        cancellable.cancel()
    }

    @Test("emitAudioLevel publishes multiple values in sequence")
    func emitAudioLevelSequence() async throws {
        let sut = MockSpeakerTestService()
        var receivedLevels: [Float] = []

        let cancellable = sut.audioLevelPublisher.sink { level in
            receivedLevels.append(level)
        }

        for level: Float in [0.1, 0.2, 0.3, 0.4, 0.5] {
            sut.emitAudioLevel(level)
        }
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(receivedLevels.count == 5)
        #expect(receivedLevels == [0.1, 0.2, 0.3, 0.4, 0.5])

        cancellable.cancel()
    }

    @Test("emitAudioLevel and stopTestSound both emit audio levels")
    func emitAndStopBothPublish() async throws {
        let sut = MockSpeakerTestService()
        var receivedLevels: [Float] = []

        let cancellable = sut.audioLevelPublisher.sink { level in
            receivedLevels.append(level)
        }

        sut.emitAudioLevel(0.5)
        sut.stopTestSound()  // Should emit 0.0
        sut.emitAudioLevel(0.3)
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(receivedLevels.count == 3)
        #expect(receivedLevels[0] == 0.5)
        #expect(receivedLevels[1] == 0.0)
        #expect(receivedLevels[2] == 0.3)

        cancellable.cancel()
    }

    // MARK: - Edge Cases

    @Test("call counts start at zero")
    func callCountsStartAtZero() {
        let sut = MockSpeakerTestService()

        #expect(sut.playTestSoundCallCount == 0)
        #expect(sut.stopTestSoundCallCount == 0)
        #expect(sut.startObservingAudioRoutesCallCount == 0)
        #expect(sut.stopObservingAudioRoutesCallCount == 0)
    }

    @Test("call counts never go negative")
    func callCountsNeverNegative() {
        let sut = MockSpeakerTestService()

        sut.stopTestSound()
        sut.stopObservingAudioRoutes()

        #expect(sut.stopTestSoundCallCount == 1)
        #expect(sut.stopObservingAudioRoutesCallCount == 1)
    }
}
