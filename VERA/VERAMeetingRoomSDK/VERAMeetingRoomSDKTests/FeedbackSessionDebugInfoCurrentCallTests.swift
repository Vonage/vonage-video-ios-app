import Testing
import VERAFeedback
import VERATestHelpers

@testable import VERAMeetingRoomSDK

@Suite("Feedback session debug info tests")
struct FeedbackSessionDebugInfoCurrentCallTests {

    @Test("fromCurrentCall returns empty when current call is not a VonageCall")
    func fromCurrentCallReturnsEmptyForNonVonageCall() {
        let repository = makeMockSessionRepository()
        repository.currentCall = MockCall()

        let debugInfo = FeedbackSessionDebugInfo.fromCurrentCall(in: repository)

        #expect(debugInfo == .empty)
    }

    @Test("fromCurrentCall returns empty when there is no active call")
    func fromCurrentCallReturnsEmptyWhenNoCall() {
        let repository = makeMockSessionRepository()

        let debugInfo = FeedbackSessionDebugInfo.fromCurrentCall(in: repository)

        #expect(debugInfo == .empty)
    }
}
