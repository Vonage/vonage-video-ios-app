//
//  Created by Vonage on 11/8/25.
//

import Foundation
import SwiftUI
import Testing
import VERACore
import VERATestHelpers

@Suite("ActiveSpeakerTracker tests")
struct ActiveSpeakerTrackerTests {

    // MARK: - Initial State Tests

    @Test func initialActiveSpeakerIsNone() async throws {
        let sut = makeSUT()
        #expect(sut.activeSpeaker == ActiveSpeakerInfo.none)
    }

    // MARK: - Single Participant Tests

    @Test func singleParticipantWithHighAudioLevelBecomesActiveSpeaker() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(
            id: "speaker1",
            name: "Arthur Dent",
            isMicEnabled: true,
            audioLevel: 0.5
        )

        sut.calculateActiveSpeaker(from: [participant])

        #expect(sut.activeSpeaker.participantId == "speaker1")
        #expect(sut.activeSpeaker.audioLevel == 0.5)
    }

    @Test func singleParticipantWithLowAudioLevelDoesNotBecomeActiveSpeaker() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(
            id: "speaker1",
            name: "Arthur Dent",
            isMicEnabled: true,
            audioLevel: 0.1  // Below threshold (background noise level)
        )

        sut.calculateActiveSpeaker(from: [participant])

        #expect(sut.activeSpeaker == ActiveSpeakerInfo.none)
    }

    @Test func participantWithMicDisabledDoesNotBecomeActiveSpeaker() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(
            id: "speaker1",
            name: "Arthur Dent",
            isMicEnabled: false,
            audioLevel: 0.5,  // High audio level but mic disabled
        )

        sut.calculateActiveSpeaker(from: [participant])

        #expect(sut.activeSpeaker == ActiveSpeakerInfo.none)
    }

    // MARK: - Multiple Participants Tests

    @Test func loudestParticipantBecomesActiveSpeaker() async throws {
        let sut = makeSUT()
        let quietParticipant = makeMockParticipant(
            id: "quiet",
            name: "Arthur Dent",
            isMicEnabled: true,
            audioLevel: 0.3  // Medium level
        )
        let loudParticipant = makeMockParticipant(
            id: "loud",
            name: "Zaphod Beeblebrox",
            isMicEnabled: true,
            audioLevel: 0.5  // High level
        )

        sut.calculateActiveSpeaker(from: [quietParticipant, loudParticipant])

        #expect(sut.activeSpeaker.participantId == "loud")
        #expect(sut.activeSpeaker.audioLevel == 0.5)
    }

    @Test func activeSpeakerChangesWhenLouderParticipantSpeaks() async throws {
        let sut = makeSUT()
        let participant1 = makeMockParticipant(
            id: "speaker1",
            name: "Arthur Dent",
            isMicEnabled: true,
            audioLevel: 0.3,  // Medium level

        )

        // First participant becomes active speaker
        sut.calculateActiveSpeaker(from: [participant1])
        #expect(sut.activeSpeaker.participantId == "speaker1")

        let participant2 = makeMockParticipant(
            id: "speaker2",
            name: "Zaphod Beeblebrox",
            isMicEnabled: true,
            audioLevel: 0.6,  // Higher level

        )

        // Second participant should become active speaker immediately
        sut.calculateActiveSpeaker(from: [participant1, participant2])
        #expect(sut.activeSpeaker.participantId == "speaker2")
        #expect(sut.activeSpeaker.audioLevel == 0.6)
    }

    @Test func noActiveSpeakerWhenAllParticipantsHaveLowAudioLevel() async throws {
        let sut = makeSUT()
        let participant1 = makeMockParticipant(
            id: "speaker1",
            audioLevel: 0.05,  // Background noise level

        )
        let participant2 = makeMockParticipant(
            id: "speaker2",
            audioLevel: 0.03,  // Even lower background noise

        )

        sut.calculateActiveSpeaker(from: [participant1, participant2])

        #expect(sut.activeSpeaker == ActiveSpeakerInfo.none)
    }

    // MARK: - Edge Cases Tests

    @Test func emptyParticipantsListResultsInNoActiveSpeaker() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(
            id: "speaker1",
            audioLevel: 0.3,  // Medium speaking level

        )

        // First set an active speaker
        sut.calculateActiveSpeaker(from: [participant])
        #expect(sut.activeSpeaker.participantId == "speaker1")

        // Empty list should clear active speaker immediately
        sut.calculateActiveSpeaker(from: [])
        #expect(sut.activeSpeaker == ActiveSpeakerInfo.none)
    }

    @Test func resetClearsActiveSpeaker() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(
            id: "speaker1",
            audioLevel: 0.3,  // Medium speaking level
        )

        sut.calculateActiveSpeaker(from: [participant])
        #expect(sut.activeSpeaker.participantId == "speaker1")

        sut.reset()
        #expect(sut.activeSpeaker == ActiveSpeakerInfo.none)
    }

    @Test func resetAllowsImmediateSpeakerChange() async throws {
        let sut = makeSUT()
        let participant1 = makeMockParticipant(
            id: "speaker1",
            audioLevel: 0.3,  // Medium speaking level

        )
        let participant2 = makeMockParticipant(
            id: "speaker2",
            audioLevel: 0.5,  // Higher speaking level

        )

        // Set first speaker
        sut.calculateActiveSpeaker(from: [participant1])
        #expect(sut.activeSpeaker.participantId == "speaker1")

        // Reset should clear cooldown
        sut.reset()

        // Should immediately allow new speaker
        sut.calculateActiveSpeaker(from: [participant2])
        #expect(sut.activeSpeaker.participantId == "speaker2")
    }

    // MARK: - Complex Scenarios Tests

    @Test func mixedParticipantsOnlyEligibleOnesConsidered() async throws {
        let sut = makeSUT()
        let micDisabledParticipant = makeMockParticipant(
            id: "mic_disabled",
            isMicEnabled: false,
            audioLevel: 0.6,  // High level but mic disabled

        )
        let lowAudioParticipant = makeMockParticipant(
            id: "low_audio",
            isMicEnabled: true,
            audioLevel: 0.05,  // Below threshold (background noise)

        )
        let validParticipant = makeMockParticipant(
            id: "valid_speaker",
            isMicEnabled: true,
            audioLevel: 0.3,  // Medium level

        )

        sut.calculateActiveSpeaker(from: [micDisabledParticipant, lowAudioParticipant, validParticipant])

        #expect(sut.activeSpeaker.participantId == "valid_speaker")
        #expect(sut.activeSpeaker.audioLevel == 0.3)
    }

    // MARK: - Threshold Boundary Tests

    @Test func participantAtExactThresholdBecomesActiveSpeaker() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(
            id: "threshold_speaker",
            isMicEnabled: true,
            audioLevel: 0.2,  // Exactly at threshold
        )

        sut.calculateActiveSpeaker(from: [participant])

        #expect(sut.activeSpeaker.participantId == "threshold_speaker")
        #expect(sut.activeSpeaker.audioLevel == 0.2)
    }

    @Test func participantJustBelowThresholdDoesNotBecomeActiveSpeaker() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(
            id: "below_threshold",
            isMicEnabled: true,
            audioLevel: 0.19,  // Just below threshold (0.2)
        )

        sut.calculateActiveSpeaker(from: [participant])

        #expect(sut.activeSpeaker == ActiveSpeakerInfo.none)
    }

    // MARK: - Active Speaker Persistence Tests

    @Test func activeSpeakerRemainsActiveUntilReplacedByLouderParticipant() async throws {
        let sut = makeSUT()
        let currentSpeaker = makeMockParticipant(
            id: "current_speaker",
            isMicEnabled: true,
            audioLevel: 0.3
        )

        // First participant becomes active speaker
        sut.calculateActiveSpeaker(from: [currentSpeaker])
        #expect(sut.activeSpeaker.participantId == "current_speaker")

        // Wait for cooldown to pass
        try await Task.sleep(for: .seconds(1.6))

        // Same participant with lower audio level should remain active speaker
        let quieterCurrentSpeaker = makeMockParticipant(
            id: "current_speaker",
            isMicEnabled: true,
            audioLevel: 0.25  // Still above threshold but lower than before
        )

        sut.calculateActiveSpeaker(from: [quieterCurrentSpeaker])
        #expect(sut.activeSpeaker.participantId == "current_speaker")
        #expect(sut.activeSpeaker.audioLevel == 0.25)

        // Only a louder participant should replace the current active speaker
        let louderParticipant = makeMockParticipant(
            id: "louder_speaker",
            isMicEnabled: true,
            audioLevel: 0.5
        )

        sut.calculateActiveSpeaker(from: [quieterCurrentSpeaker, louderParticipant])
        #expect(sut.activeSpeaker.participantId == "louder_speaker")
        #expect(sut.activeSpeaker.audioLevel == 0.5)
    }

    // MARK: - Performance Tests

    @Test func calculationWithManyParticipantsPerformsWell() async throws {
        let sut = makeSUT()

        // Create 100 participants with realistic audio level
        let participants = (1...100).map { index in
            makeMockParticipant(
                id: "participant_\(index)",
                name: "Participant \(index)",
                isMicEnabled: index % 3 == 0,  // Every 3rd participant has mic enabled
                audioLevel: 0.2 + (Float(index) / 200.0),  // Audio levels from 0.205 to 0.7

            )
        }

        let startTime = Date()
        sut.calculateActiveSpeaker(from: participants)
        let endTime = Date()

        let executionTime = endTime.timeIntervalSince(startTime)
        #expect(executionTime < 0.1, "Calculation should complete within 100ms")

        // Should pick the participant with highest audio level among those with mic enabled
        // Participant 99 should be the active speaker (index 99, mic enabled, highest audio level ~0.7)
        #expect(sut.activeSpeaker.participantId == "participant_99")
        #expect(sut.activeSpeaker.audioLevel > 0.6)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> ActiveSpeakerTracker {
        ActiveSpeakerTracker()
    }
}
