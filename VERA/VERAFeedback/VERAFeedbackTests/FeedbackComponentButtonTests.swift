import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback component button tests")
struct FeedbackComponentButtonTests {

    @Test("FeedbackButton builds without crashing")
    func feedbackButtonBuilds() {
        let button = FeedbackButton(onShowFeedbackForm: {})
        _ = button.body
        #expect(true)
    }

    @Test("FeedbackComponentButton builds without crashing")
    func feedbackComponentButtonBuilds() {
        let view = FeedbackComponentButton(onShowFeedbackForm: {})
        _ = view.body
        #expect(true)
    }
}
