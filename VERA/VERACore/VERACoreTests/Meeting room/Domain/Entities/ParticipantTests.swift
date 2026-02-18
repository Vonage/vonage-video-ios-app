//
//  Created by Vonage on 15/9/25.
//

import Foundation
import Testing
import VERACore
import VERADomain
import VERATestHelpers

@Suite("Participant tests")
struct ParticipantTests {

    @Test(
        "Participant config returns expected values",
        arguments: [
            SpeakerInfo(id: "an id", audioLevel: 0.0, isMicEnabled: true),
            SpeakerInfo(id: "another id", audioLevel: 0.1, isMicEnabled: false),
        ])
    func getSpeakerInfoWithZeroAudioLevelReturnsExpectedValues(testCase: SpeakerInfo) async throws {
        let sut = makeSUT(id: testCase.id, isMicEnabled: testCase.isMicEnabled)

        let speakerInfo = sut.getSpeakerInfo(testCase.audioLevel)

        #expect(speakerInfo.id == testCase.id)
        #expect(speakerInfo.audioLevel == testCase.audioLevel)
        #expect(speakerInfo.isMicEnabled == testCase.isMicEnabled)
    }

    @Test("Participants with different connectionId are not equal")
    func participantsWithDifferentConnectionIdAreNotEqual() {
        let participant1 = makeSUT(connectionId: "connection-1")
        let participant2 = makeSUT(connectionId: "connection-2")

        #expect(participant1 != participant2)
    }

    @Test("Participants with same connectionId are equal")
    func participantsWithSameConnectionIdAreEqual() {
        let participant1 = makeSUT(connectionId: "connection-1")
        let participant2 = makeSUT(connectionId: "connection-1")

        #expect(participant1 == participant2)
    }

    @Test("Participants with nil vs non-nil connectionId are not equal")
    func participantsWithNilVsNonNilConnectionIdAreNotEqual() {
        let participant1 = makeSUT(connectionId: nil)
        let participant2 = makeSUT(connectionId: "connection-1")

        #expect(participant1 != participant2)
    }

    @Test("Participant hash differs when connectionId differs")
    func participantHashDiffersWhenConnectionIdDiffers() {
        let participant1 = makeSUT(connectionId: "connection-1")
        let participant2 = makeSUT(connectionId: "connection-2")

        #expect(participant1.hashValue != participant2.hashValue)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        id: String = "an id",
        connectionId: String? = nil,
        isMicEnabled: Bool = true
    ) -> Participant {
        makeMockParticipant(
            id: id,
            connectionId: connectionId,
            isMicEnabled: isMicEnabled)
    }
}
