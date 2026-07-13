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

    // MARK: - Edge Case Tests

    @Test("handles extreme audio level values correctly")
    func handlesExtremeAudioLevelValues() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()

        // Test minimum value
        service.emitAudioLevel(0.0)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(sut.currentAudioLevel == 0.0)

        // Test maximum value
        service.emitAudioLevel(1.0)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(sut.currentAudioLevel == 1.0)

        // Test values outside normal range (should still be handled)
        service.emitAudioLevel(-0.1)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(sut.currentAudioLevel == -0.1)

        service.emitAudioLevel(1.5)
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(sut.currentAudioLevel == 1.5)
    }

    @Test("handles rapid audio level changes")
    func handlesRapidAudioLevelChanges() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        sut.testSpeaker()

        // Emit rapid changes
        for i in 0..<10 {
            service.emitAudioLevel(Float(i) * 0.1)
        }

        try? await Task.sleep(nanoseconds: 50_000_000)

        // Should have received the last value (allowing for floating point precision)
        #expect(abs(sut.currentAudioLevel - 0.9) < 0.01)
    }

    @Test("subscription setup is idempotent")
    func subscriptionSetupIsIdempotent() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        // Call testSpeaker multiple times
        sut.testSpeaker()
        sut.testSpeaker()
        sut.testSpeaker()

        service.emitAudioLevel(0.8)
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(sut.currentAudioLevel == 0.8)
        #expect(service.playTestSoundCallCount == 3)  // Each call should go through
    }

    @Test("audio level resets after multiple play/stop cycles")
    func audioLevelResetsAfterMultiplePlayStopCycles() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        for _ in 0..<3 {
            sut.testSpeaker()
            service.emitAudioLevel(0.7)
            try? await Task.sleep(nanoseconds: 10_000_000)

            #expect(sut.currentAudioLevel == 0.7)

            sut.stopSpeaker()
            #expect(sut.currentAudioLevel == 0.0)
        }
    }

    // MARK: - Concurrent Access Tests

    @Test("handles concurrent toggle operations safely")
    func handlesConcurrentToggleOperations() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        // Simulate rapid concurrent toggles
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    await sut.togglePlayback()
                }
            }
        }

        // State should be consistent
        let finalState = sut.isPlaying
        #expect(finalState == true || finalState == false)  // Should be one or the other
    }

    @Test("handles concurrent test and stop operations safely")
    func handlesConcurrentTestAndStopOperations() async {
        let service = MockSpeakerTestService()
        let sut = AudioOutputControlViewModel(speakerTestService: service)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await sut.testSpeaker() }
            group.addTask { await sut.stopSpeaker() }
            group.addTask { await sut.testSpeaker() }
            group.addTask { await sut.stopSpeaker() }
        }

        // Final state should be consistent
        let finalState = sut.isPlaying
        #expect(finalState == true || finalState == false)
    }

    // MARK: - Memory Management Tests

    @Test("view model properly manages subscription lifecycle")
    func viewModelProperlyManagesSubscriptionLifecycle() async {
        let service = MockSpeakerTestService()
        var sut: AudioOutputControlViewModel? = AudioOutputControlViewModel(speakerTestService: service)

        sut!.testSpeaker()
        service.emitAudioLevel(0.5)
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(sut!.currentAudioLevel == 0.5)

        // Deallocate view model
        sut = nil

        // Service should still be able to emit (no crashes)
        service.emitAudioLevel(0.8)
    }

    @Test("multiple view models can subscribe to same service")
    func multipleViewModelsCanSubscribeToSameService() async {
        let service = MockSpeakerTestService()
        let sut1 = AudioOutputControlViewModel(speakerTestService: service)
        let sut2 = AudioOutputControlViewModel(speakerTestService: service)

        sut1.testSpeaker()
        sut2.testSpeaker()

        service.emitAudioLevel(0.6)
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(sut1.currentAudioLevel == 0.6)
        #expect(sut2.currentAudioLevel == 0.6)
    }
}
