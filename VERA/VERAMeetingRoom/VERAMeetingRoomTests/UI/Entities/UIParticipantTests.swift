import Testing
import VERATestHelpers

@testable import VERAMeetingRoom

@MainActor
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

    @Test
    @MainActor
    func displayNameAddsScreenSuffixOnlyForScreenShares() {
        let camera = UIParticipant(participant: makeMockParticipant(name: "Alice"))
        let screen = UIParticipant(participant: makeMockParticipant(name: "Alice", isScreenshare: true))

        #expect(camera.displayName == "Alice")
        #expect(screen.displayName == "Alice's screen")
    }
}
