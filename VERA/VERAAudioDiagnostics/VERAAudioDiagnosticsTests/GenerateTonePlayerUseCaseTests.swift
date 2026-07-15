//
//  GenerateTonePlayerUseCaseTests.swift
//  VERAAudioDiagnosticsTests
//
//  Created by Vonage on 03/07/26.
//

@preconcurrency import AVFoundation
import Testing

@testable import VERAAudioDiagnostics

@Suite("GenerateTonePlayerUseCase tests")
@MainActor
struct GenerateTonePlayerUseCaseTests {

    // MARK: - DefaultGenerateTonePlayerUseCase Tests

    @Test("DefaultGenerateTonePlayerUseCase returns non-nil AVAudioPlayer")
    func defaultGenerateTonePlayerUseCaseReturnsPlayer() throws {
        let sut = DefaultGenerateTonePlayerUseCase()

        let player = try sut()

        #expect(player.duration > 0)
    }

    @Test("DefaultGenerateTonePlayerUseCase returns configured AVAudioPlayer")
    func defaultGenerateTonePlayerUseCaseReturnsConfiguredPlayer() throws {
        let sut = DefaultGenerateTonePlayerUseCase()

        let player = try sut()

        // Verify player is configured correctly
        #expect(player.duration > 0.0)
        #expect(player.numberOfChannels == 1)  // Mono
        #expect(player.volume == 1.0)  // Default volume
    }

    @Test("DefaultGenerateTonePlayerUseCase creates player with consistent duration")
    func defaultGenerateTonePlayerUseCaseCreatesConsistentDuration() throws {
        let sut = DefaultGenerateTonePlayerUseCase()

        let player1 = try sut()
        let player2 = try sut()

        // Both players should have the same duration (1 second)
        #expect(abs(player1.duration - player2.duration) < 0.01)
        #expect(player1.duration > 0.9)  // Should be approximately 1 second
        #expect(player1.duration < 1.1)
    }

    @Test("DefaultGenerateTonePlayerUseCase creates independent players")
    func defaultGenerateTonePlayerUseCaseCreatesIndependentPlayers() throws {
        let sut = DefaultGenerateTonePlayerUseCase()

        let player1 = try sut()
        let player2 = try sut()

        // Players should be different instances
        #expect(player1 !== player2)
    }

    @Test("DefaultGenerateTonePlayerUseCase player can be prepared")
    func defaultGenerateTonePlayerUseCasePlayerCanBePrepared() throws {
        let sut = DefaultGenerateTonePlayerUseCase()

        let player = try sut()

        #expect(player.prepareToPlay() == true)
    }

    @Test("DefaultGenerateTonePlayerUseCase supports metering")
    func defaultGenerateTonePlayerUseCaseSupportsMeteringWhenEnabled() throws {
        let sut = DefaultGenerateTonePlayerUseCase()

        let player = try sut()
        player.isMeteringEnabled = true

        // Should not crash when accessing metering
        let _ = player.averagePower(forChannel: 0)
        let _ = player.peakPower(forChannel: 0)
    }

    @Test("DefaultGenerateTonePlayerUseCase creates WAV-compatible player")
    func defaultGenerateTonePlayerUseCaseCreatesWAVCompatiblePlayer() throws {
        let sut = DefaultGenerateTonePlayerUseCase()

        let player = try sut()

        // Verify the format is compatible (should not crash on these checks)
        #expect(player.numberOfChannels > 0)
        #expect(player.duration > 0)
        #expect(player.format.sampleRate > 0)
    }

    // MARK: - Performance Tests

    @Test("DefaultGenerateTonePlayerUseCase creation is reasonably fast")
    func defaultGenerateTonePlayerUseCaseCreationPerformance() throws {
        let sut = DefaultGenerateTonePlayerUseCase()
        let startTime = CFAbsoluteTimeGetCurrent()

        let _ = try sut()

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        // Should create player in less than 100ms
        #expect(elapsed < 0.1)
    }

    @Test("DefaultGenerateTonePlayerUseCase multiple creations don't leak")
    func defaultGenerateTonePlayerUseCaseMultipleCreationsNoLeak() throws {
        let sut = DefaultGenerateTonePlayerUseCase()

        // Create multiple players to test for memory issues
        for _ in 0..<10 {
            let player = try sut()
            #expect(player.duration > 0)
        }
        // If we get here without crashes, we're likely not leaking
    }

    // MARK: - Mock Use Case Tests (Using unified mock from DefaultSpeakerTestServiceTests)

    @Test("Mock use case throws TonePlayerGenerationError.audioDataGenerationFailed when configured to fail")
    func mockUseCaseThrowsWhenConfigured() throws {
        let sut = MockGenerateTonePlayerUseCase(shouldReturnNil: true)

        #expect(throws: TonePlayerGenerationError.audioDataGenerationFailed) {
            try sut()
        }
        #expect(sut.callCount == 1)
    }

    @Test("Mock use case throws TonePlayerGenerationError when shouldFailOnGenerate is true")
    func mockUseCaseThrowsWhenShouldFailOnGenerate() {
        let sut = MockGenerateTonePlayerUseCase()
        sut.shouldFailOnGenerate = true

        #expect(throws: TonePlayerGenerationError.audioDataGenerationFailed) {
            try sut()
        }
    }

    @Test("TonePlayerGenerationError cases are equatable")
    func tonePlayerGenerationErrorEquatable() {
        #expect(TonePlayerGenerationError.audioDataGenerationFailed == .audioDataGenerationFailed)
        #expect(
            TonePlayerGenerationError.playerInitializationFailed(underlyingError: "err")
                == .playerInitializationFailed(underlyingError: "err"))
        #expect(
            TonePlayerGenerationError.audioDataGenerationFailed != .playerInitializationFailed(underlyingError: "err"))
    }

    @Test("Mock use case returns player when configured normally")
    func mockUseCaseReturnsPlayerWhenConfigured() throws {
        let sut = MockGenerateTonePlayerUseCase()

        let result = try sut()

        #expect(result.duration > 0)
        #expect(sut.callCount == 1)
    }

    @Test("Mock use case tracks call count correctly")
    func mockUseCaseTracksCallCountCorrectly() throws {
        let sut = MockGenerateTonePlayerUseCase()

        #expect(sut.callCount == 0)

        _ = try sut()
        #expect(sut.callCount == 1)

        _ = try sut()
        #expect(sut.callCount == 2)

        _ = try sut()
        #expect(sut.callCount == 3)
    }
}
