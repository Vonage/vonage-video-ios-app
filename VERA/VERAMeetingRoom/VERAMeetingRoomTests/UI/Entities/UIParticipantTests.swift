import Testing
import VERATestHelpers

@testable import VERAMeetingRoom

@Suite("UI participant tests")
struct UIParticipantTests {
    @Test
    func canForceMuteIsFalseWithoutAction() {
        let sut = UIParticipant(participant: makeMockParticipant())

        #expect(!sut.canForceMute)
    }

    @Test
    func canForceMuteIsTrueWithAction() {
        var sut = UIParticipant(participant: makeMockParticipant())
        sut.onForceMute = {}

        #expect(sut.canForceMute)
    }
}
