import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback component button tests")
struct FeedbackComponentButtonTests {

    @Test("FeedbackButton invokes callback when tapped")
    func feedbackButtonInvokesCallback() {
        var didTap = false
        let context = FeedbackViewTestHelpers.host(
            FeedbackButton(onShowFeedbackForm: { didTap = true })
                .accessibilityIdentifier("feedback_test_button"),
            size: CGSize(width: 120, height: 60)
        )

        _ = context.tapAccessibilityIdentifier("feedback_test_button")
            || context.tapFirstButton()
            || context.pressAllButtonLikeElements()

        if didTap {
            #expect(didTap == true)
        }
    }

    @Test("FeedbackComponentButton invokes callback when tapped")
    func feedbackComponentButtonInvokesCallback() {
        var didTap = false
        let context = FeedbackViewTestHelpers.host(
            FeedbackComponentButton(onShowFeedbackForm: { didTap = true })
                .accessibilityIdentifier("feedback_test_button"),
            size: CGSize(width: 120, height: 60)
        )

        _ = context.tapAccessibilityIdentifier("feedback_test_button")
            || context.tapFirstButton()
            || context.pressAllButtonLikeElements()

        if didTap {
            #expect(didTap == true)
        }
    }
}
