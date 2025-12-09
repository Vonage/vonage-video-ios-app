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

    // MARK: - Test Helpers

    private func makeSUT(
        id: String = "an id",
        isMicEnabled: Bool = true
    ) -> Participant {
        makeMockParticipant(
            id: id,
            isMicEnabled: isMicEnabled)
    }
}
