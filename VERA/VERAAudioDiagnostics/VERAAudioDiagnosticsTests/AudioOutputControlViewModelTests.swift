//
//  Created by Vonage on 07/07/26.
//

import Combine
import Testing

@testable import VERAAudioDiagnostics

@Suite("AudioOutputControlViewModel tests")
@MainActor
struct AudioOutputControlViewModelTests {

    // MARK: - Initialization Tests

    @Test("initializes with default values")
    func initializesWithDefaultValues() {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        #expect(sut.currentAudioLevel == 0.0)
        #expect(sut.isPlaying == false)
    }

    // MARK: - Test Speaker Tests

    @Test("testSpeaker calls playTestSound on service")
    func testSpeakerCallsPlayTestSound() {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()

        #expect(service.playTestSoundCallCount == 1)
        #expect(sut.isPlaying == true)
    }

    @Test("testSpeaker updates isPlaying to true")
    func testSpeakerUpdatesIsPlaying() {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()

        #expect(sut.isPlaying == true)
    }

    @Test("testSpeaker subscribes to audio level publisher")
    func testSpeakerSubscribesToAudioLevel() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()

        // Emit audio level
        service.emitAudioLevel(0.5)

        // Give time for publisher to emit
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(sut.currentAudioLevel == 0.5)
    }

    // MARK: - Stop Speaker Tests

    @Test("stopSpeaker calls stopTestSound on service")
    func stopSpeakerCallsStopTestSound() {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()
        sut.stopSpeaker()

        #expect(service.stopTestSoundCallCount == 1)
    }

    @Test("stopSpeaker updates isPlaying to false")
    func stopSpeakerUpdatesIsPlaying() {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()
        sut.stopSpeaker()

        #expect(sut.isPlaying == false)
    }

    @Test("stopSpeaker resets currentAudioLevel to zero")
    func stopSpeakerResetsAudioLevel() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()
        service.emitAudioLevel(0.8)

        try? await Task.sleep(nanoseconds: 10_000_000)

        sut.stopSpeaker()

        #expect(sut.currentAudioLevel == 0.0)
    }

    // MARK: - Toggle Playback Tests

    @Test("togglePlayback starts playing when stopped")
    func togglePlaybackStartsWhenStopped() {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.togglePlayback()

        #expect(sut.isPlaying == true)
        #expect(service.playTestSoundCallCount == 1)
    }

    @Test("togglePlayback stops playing when started")
    func togglePlaybackStopsWhenStarted() {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()
        sut.togglePlayback()

        #expect(sut.isPlaying == false)
        #expect(service.stopTestSoundCallCount == 1)
    }

    @Test("togglePlayback twice goes from stopped to playing to stopped")
    func togglePlaybackTwice() {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.togglePlayback()
        #expect(sut.isPlaying == true)

        sut.togglePlayback()
        #expect(sut.isPlaying == false)
    }

    // MARK: - Audio Level Publisher Tests

    @Test("receives multiple audio level updates")
    func receivesMultipleAudioLevelUpdates() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()

        service.emitAudioLevel(0.2)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(sut.currentAudioLevel == 0.2)

        service.emitAudioLevel(0.5)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(sut.currentAudioLevel == 0.5)

        service.emitAudioLevel(0.9)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(sut.currentAudioLevel == 0.9)
    }

    @Test("audio level updates only after testSpeaker is called")
    func audioLevelUpdatesOnlyAfterTestSpeaker() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        // Emit without starting playback
        service.emitAudioLevel(0.7)
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Should still be 0 because subscription not established
        #expect(sut.currentAudioLevel == 0.0)

        // Now start playback
        sut.testSpeaker()
        service.emitAudioLevel(0.7)
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Now should update
        #expect(sut.currentAudioLevel == 0.7)
    }
}

// MARK: - Mock Speaker Test Service

@MainActor
private final class MockSpeakerTestService: SpeakerTestService {
    private let audioLevelSubject = PassthroughSubject<Float, Never>()

    var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private(set) var playTestSoundCallCount = 0
    private(set) var stopTestSoundCallCount = 0

    func playTestSound() {
        playTestSoundCallCount += 1
    }

    func stopTestSound() {
        stopTestSoundCallCount += 1
        audioLevelSubject.send(0.0)
    }

    func emitAudioLevel(_ level: Float) {
        audioLevelSubject.send(level)
    }
}
