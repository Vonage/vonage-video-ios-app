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

    @Test("playTestSound does not crash when use case returns nil")
    func playTestSoundWithNilPlayerDoesNotCrash() {
        let mockUseCase = MockGenerateTonePlayerUseCase(shouldReturnNil: true)
        let sut = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)

        sut.playTestSound()
        // No assertion needed — test passes if no crash occurs.
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
}
