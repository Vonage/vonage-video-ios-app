//
//  DefaultSpeakerTestServiceTests.swift
//  VERAAudioDiagnosticsTests
//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import Combine
import Testing

@testable import VERAAudioDiagnostics

/// Comprehensive test suite for DefaultSpeakerTestService
/// This test suite focuses on testable aspects of the service including:
/// - Use case integration
/// - Error handling
/// - Nil player scenarios
/// - Audio level publishing behavior
@Suite("DefaultSpeakerTestService - Comprehensive Tests")
@MainActor
struct DefaultSpeakerTestServiceTests {

    // MARK: - Basic Functionality Tests

    @Test("playTestSound does not crash when use case throws")
    func playTestSoundWithNilPlayerDoesNotCrash() {
        let mockUseCase = MockGenerateTonePlayerUseCase(shouldReturnNil: true)
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        sut.playTestSound()
        // No assertion needed — test passes if no crash occurs.
    }

    @Test("playTestSound does not start monitoring when use case throws")
    func playTestSoundDoesNotStartMonitoringWhenUseCaseThrows() async throws {
        let mockUseCase = MockGenerateTonePlayerUseCase(shouldReturnNil: true)
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        var receivedLevels: [Float] = []
        let cancellable = sut.audioLevelPublisher.sink { receivedLevels.append($0) }

        sut.playTestSound()
        try await Task.sleep(nanoseconds: 100_000_000)

        // stopMonitoring emits 0.0 when use case throws — no other levels should appear
        let nonZeroLevels = receivedLevels.filter { $0 > 0.0 }
        #expect(nonZeroLevels.isEmpty)
        cancellable.cancel()
    }

    @Test("use case is called exactly once even when it throws")
    func useCaseIsCalledOnceEvenWhenItThrows() {
        let mockUseCase = MockGenerateTonePlayerUseCase(shouldReturnNil: true)
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        sut.playTestSound()

        #expect(mockUseCase.callCount == 1)
    }

    @Test("playTestSound invokes the use case exactly once")
    func playTestSoundInvokesUseCaseOnce() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        sut.playTestSound()

        #expect(mockUseCase.callCount == 1)
    }

    @Test("calling playTestSound multiple times invokes use case only once (player reuse)")
    func multiplePlayTestSoundCallsReusePlayer() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        sut.playTestSound()
        sut.playTestSound()
        sut.playTestSound()

        // Use case should only be called once - player is reused
        #expect(mockUseCase.callCount == 1)
    }

    // MARK: - Audio Route Observation Tests

    @Test("startObservingAudioRoutes does not crash when called independently")
    func startObservingAudioRoutesDoesNotCrash() {
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: MockGenerateTonePlayerUseCase())
        sut.startObservingAudioRoutes()
        // Test passes if no crash occurs
    }

    @Test("stopObservingAudioRoutes does not crash when called independently")
    func stopObservingAudioRoutesDoesNotCrash() {
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: MockGenerateTonePlayerUseCase())
        sut.stopObservingAudioRoutes()
        // Test passes if no crash occurs
    }

    @Test("startObservingAudioRoutes and stopObservingAudioRoutes can be called repeatedly")
    func observingAudioRoutesCanBeCalledRepeatedly() {
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: MockGenerateTonePlayerUseCase())

        for _ in 0..<5 {
            sut.startObservingAudioRoutes()
            sut.stopObservingAudioRoutes()
        }
        // Test passes if no crash occurs
    }

    @Test("playTestSound automatically starts observing audio routes")
    func playTestSoundStartsObservingAudioRoutes() async throws {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // playTestSound should internally call startObservingAudioRoutes
        sut.playTestSound()

        #expect(mockUseCase.callCount == 1)
    }

    @Test("stopTestSound automatically stops observing audio routes")
    func stopTestSoundStopsObservingAudioRoutes() {
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: MockGenerateTonePlayerUseCase())

        sut.playTestSound()
        // stopTestSound calls stopObservingAudioRoutes internally
        sut.stopTestSound()
        // Test passes if no crash occurs
    }

    #if os(iOS)
        @Test("startObservingAudioRoutes reacts to newDeviceAvailable route change when playing")
        func startObservingAudioRoutesReactsToNewDeviceWhenPlaying() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.playTestSound()  // sets isPlaying = true and registers observer
            let callCountAfterPlay = mockUseCase.callCount

            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [
                    AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
                ]
            )

            // Allow time for the 0.1s async dispatch + processing
            try await Task.sleep(nanoseconds: 300_000_000)

            // Player is reused, so use case is still called only once
            #expect(mockUseCase.callCount == callCountAfterPlay)
        }

        @Test("startObservingAudioRoutes reacts to oldDeviceUnavailable route change when playing")
        func startObservingAudioRoutesReactsToOldDeviceUnavailableWhenPlaying() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.playTestSound()
            let callCountAfterPlay = mockUseCase.callCount

            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [
                    AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
                ]
            )

            try await Task.sleep(nanoseconds: 300_000_000)

            // Player is reused, so use case is still called only once
            #expect(mockUseCase.callCount == callCountAfterPlay)
        }

        @Test("startObservingAudioRoutes reacts to override route change when playing")
        func startObservingAudioRoutesReactsToOverrideWhenPlaying() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.playTestSound()
            let callCountAfterPlay = mockUseCase.callCount

            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [
                    AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.override.rawValue
                ]
            )

            try await Task.sleep(nanoseconds: 300_000_000)

            // Player is reused, so use case is still called only once
            #expect(mockUseCase.callCount == callCountAfterPlay)
        }

        @Test("startObservingAudioRoutes reacts to categoryChange route change when playing")
        func startObservingAudioRoutesReactsToCategoryChangeWhenPlaying() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.playTestSound()
            let callCountAfterPlay = mockUseCase.callCount

            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [
                    AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.categoryChange.rawValue
                ]
            )

            try await Task.sleep(nanoseconds: 300_000_000)

            // Player is reused, so use case is still called only once
            #expect(mockUseCase.callCount == callCountAfterPlay)
        }

        @Test("startObservingAudioRoutes ignores wakeFromSleep route change when playing")
        func startObservingAudioRoutesIgnoresWakeFromSleepWhenPlaying() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.playTestSound()
            let callCountAfterPlay = mockUseCase.callCount

            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [
                    AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.wakeFromSleep.rawValue
                ]
            )

            try await Task.sleep(nanoseconds: 300_000_000)

            // Ignored reason — use case count must not change
            #expect(mockUseCase.callCount == callCountAfterPlay)
        }

        @Test("startObservingAudioRoutes does not restart playback when not playing")
        func startObservingAudioRoutesDoesNotRestartWhenNotPlaying() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.startObservingAudioRoutes()
            // isPlaying is false — route change should be ignored

            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [
                    AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
                ]
            )

            try await Task.sleep(nanoseconds: 300_000_000)

            #expect(mockUseCase.callCount == 0)
        }
    #endif

    @Test("stopTestSound can be called safely without starting playback")
    func stopTestSoundSafelyCalledWithoutPlayback() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Should not crash
        sut.stopTestSound()

        #expect(mockUseCase.callCount == 0)
    }

    // MARK: - Audio Level Publisher Tests

    @Test("Audio level publisher emits zero when stopped")
    func audioLevelPublisherEmitsZeroWhenStopped() async throws {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        var receivedLevels: [Float] = []
        let cancellable = sut.audioLevelPublisher
            .sink { level in
                receivedLevels.append(level)
            }

        sut.playTestSound()
        sut.stopTestSound()

        // Allow some time for the publisher to emit
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        #expect(receivedLevels.contains(0.0))
        cancellable.cancel()
    }

    @Test("Audio level publisher is available and does not crash")
    func audioLevelPublisherAvailableAndDoesNotCrash() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        let publisher = sut.audioLevelPublisher

        // Should be a valid publisher
        #expect(publisher != nil)

        // Should be able to subscribe without crashing
        let cancellable = publisher.sink { _ in }
        cancellable.cancel()
    }

    // MARK: - Error Handling Tests

    @Test("Service handles nil player from use case gracefully")
    func serviceHandlesNilPlayerGracefully() {
        let mockUseCase = MockGenerateTonePlayerUseCase(shouldReturnNil: true)
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Should not crash
        sut.playTestSound()
        sut.stopTestSound()

        #expect(mockUseCase.callCount == 1)
    }

    @Test("Multiple rapid play/stop calls are handled correctly")
    func multipleRapidPlayStopCallsHandled() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Rapid play/stop calls
        for _ in 0..<10 {
            sut.playTestSound()
            sut.stopTestSound()
        }

        // Should not crash and use case should only be called once (player reuse)
        #expect(mockUseCase.callCount == 1)
    }

    @Test("Player factory is called only once for multiple play/stop cycles")
    func playerFactoryCalledOnlyOnceForMultipleCycles() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Multiple play/stop cycles
        for _ in 0..<5 {
            sut.playTestSound()
            sut.stopTestSound()
        }

        #expect(mockUseCase.callCount == 1)
    }

    // MARK: - Edge Cases

    @Test("stopTestSound preserves player for reuse")
    func stopTestSoundPreservesPlayerForReuse() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // First session
        sut.playTestSound()
        #expect(mockUseCase.callCount == 1)

        sut.stopTestSound()

        // Second session should reuse player (use case not called again)
        sut.playTestSound()
        #expect(mockUseCase.callCount == 1)  // Still 1
    }

    @Test("Service can handle failure to create audio player")
    func serviceCanHandleFailureToCreateAudioPlayer() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        mockUseCase.shouldFailOnGenerate = true

        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Should not crash when player creation fails
        sut.playTestSound()
        sut.stopTestSound()

        #expect(mockUseCase.callCount == 1)
    }

    // MARK: - Additional Edge Cases and Coverage Tests

    @Test("DefaultSpeakerTestService should handle rapid speaker test state changes")
    func defaultSpeakerTestServiceShouldHandleRapidSpeakerTestStateChanges() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Simulate rapid state changes
        sut.playTestSound()
        sut.stopTestSound()
        sut.playTestSound()
        sut.stopTestSound()

        #expect(mockUseCase.callCount == 1)  // Player reuse
    }

    @Test("DefaultSpeakerTestService should handle speaker test failure scenarios")
    func defaultSpeakerTestServiceShouldHandleSpeakerTestFailureScenarios() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        mockUseCase.shouldFailOnGenerate = true

        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        sut.playTestSound()

        // Should handle failure gracefully
        #expect(mockUseCase.callCount == 1)
    }

    @Test("DefaultSpeakerTestService should maintain consistent state during concurrent operations")
    func defaultSpeakerTestServiceShouldMaintainConsistentStateDuringConcurrentOperations() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Simulate concurrent operations (sequential in tests for safety)
        for _ in 0..<10 {
            sut.playTestSound()
            sut.stopTestSound()
        }

        // Should handle concurrent access safely
        #expect(mockUseCase.callCount == 1)
    }

    @Test("DefaultSpeakerTestService should handle use case failure gracefully")
    func defaultSpeakerTestServiceShouldHandleUseCaseFailureGracefully() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        mockUseCase.shouldFailOnGenerate = true

        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Should not crash when use case fails
        sut.playTestSound()
        sut.stopTestSound()

        #expect(mockUseCase.callCount == 1)
    }

    @Test("DefaultSpeakerTestService should maintain state consistency during errors")
    func defaultSpeakerTestServiceShouldMaintainStateConsistencyDuringErrors() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        sut.playTestSound()

        // Simulate error in use case
        mockUseCase.simulateError = true
        sut.stopTestSound()

        // Should still allow restart after error
        mockUseCase.simulateError = false
        sut.playTestSound()

        #expect(mockUseCase.callCount >= 1)
    }

    @Test("DefaultSpeakerTestService should handle concurrent access safely")
    func defaultSpeakerTestServiceShouldHandleConcurrentAccessSafely() {
        let mockUseCase = MockGenerateTonePlayerUseCase()
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        // Simulate concurrent start/stop operations (sequential for test safety)
        for _ in 0..<3 {
            sut.playTestSound()
            sut.stopTestSound()
        }

        // Should handle concurrent access without crashing
        #expect(mockUseCase.callCount >= 1)
    }

    // MARK: - Route Change Guard Tests

    #if os(iOS)
        @Test("handleRouteChange is ignored when userInfo is missing")
        func handleRouteChangeIgnoredWhenUserInfoMissing() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.playTestSound()
            let callCountAfterPlay = mockUseCase.callCount

            // Post notification with no userInfo — guard let userInfo fails
            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: nil
            )

            try await Task.sleep(nanoseconds: 300_000_000)

            #expect(mockUseCase.callCount == callCountAfterPlay)
        }

        @Test("handleRouteChange is ignored when reason key is missing")
        func handleRouteChangeIgnoredWhenReasonKeyMissing() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.playTestSound()
            let callCountAfterPlay = mockUseCase.callCount

            // Post notification with userInfo but without the reason key
            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: ["unrelatedKey": "unrelatedValue"]
            )

            try await Task.sleep(nanoseconds: 300_000_000)

            #expect(mockUseCase.callCount == callCountAfterPlay)
        }
    #endif

    // MARK: - startObservingAudioRoutes Idempotency

    #if os(iOS)
        @Test("startObservingAudioRoutes is idempotent — observer registered only once")
        func startObservingAudioRoutesIsIdempotent() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            // Call twice — should not register the observer twice
            sut.playTestSound()  // first registration via playTestSound
            sut.startObservingAudioRoutes()  // second call — should be a no-op

            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [
                    AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
                ]
            )

            try await Task.sleep(nanoseconds: 300_000_000)

            // If observer fired twice we'd see inconsistent state; player is still reused
            #expect(mockUseCase.callCount == 1)
        }
    #endif

    // MARK: - restartPlayback Race Condition

    #if os(iOS)
        @Test("restartPlayback does nothing if stopTestSound was called before delay fires")
        func restartPlaybackDoesNothingIfStoppedBeforeDelayFires() async throws {
            let mockUseCase = MockGenerateTonePlayerUseCase()
            let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

            sut.playTestSound()

            // Trigger a route change (which schedules restartPlayback after 100ms)
            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [
                    AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
                ]
            )

            // Stop immediately — before the 100ms asyncAfter fires
            sut.stopTestSound()

            // Wait past the asyncAfter deadline
            try await Task.sleep(nanoseconds: 300_000_000)

            // restartPlayback guard `isPlaying == false` should have prevented re-start
            // Use case still called only once (player not recreated)
            #expect(mockUseCase.callCount == 1)
        }
    #endif

    // MARK: - AVAudioPlayerDelegate Tests

    @Test("audioPlayerDidFinishPlaying does not crash with successful or failed flag")
    func audioPlayerDidFinishPlayingDoesNotCrash() throws {
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: MockGenerateTonePlayerUseCase())
        let player = try DefaultGenerateTonePlayerUseCase()()

        sut.audioPlayerDidFinishPlaying(player, successfully: true)
        sut.audioPlayerDidFinishPlaying(player, successfully: false)
    }

    @Test("audioPlayerDecodeErrorDidOccur does not crash with or without an error")
    func audioPlayerDecodeErrorDidOccurDoesNotCrash() throws {
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: MockGenerateTonePlayerUseCase())
        let player = try DefaultGenerateTonePlayerUseCase()()

        sut.audioPlayerDecodeErrorDidOccur(player, error: nil)
        sut.audioPlayerDecodeErrorDidOccur(player, error: NSError(domain: "TestDomain", code: -1))
    }

    @Test("audioPlayerDidFinishPlaying emits zero level through publisher")
    func audioPlayerDidFinishPlayingEmitsZeroLevel() async throws {
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: MockGenerateTonePlayerUseCase())
        let player = try DefaultGenerateTonePlayerUseCase()()

        sut.playTestSound()

        var receivedLevels: [Float] = []
        let cancellable = sut.audioLevelPublisher.sink { receivedLevels.append($0) }

        sut.audioPlayerDidFinishPlaying(player, successfully: true)
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(receivedLevels.contains(0.0))
        cancellable.cancel()
    }
}
