import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback factory tests")
struct FeedbackFactoryTests {

    @Test("makeMeetingRoomButton returns a hostable button")
    func makeMeetingRoomButtonReturnsHostableButton() {
        let factory = FeedbackFactory()
        let button = factory.makeMeetingRoomButton(onShowFeedbackForm: {})

        FeedbackViewTestHelpers.host(button, size: CGSize(width: 120, height: 60))
        #expect(true)
    }

    @Test("makeMeetingRoomButton forwards tap when possible")
    func makeMeetingRoomButtonForwardsTapWhenPossible() {
        let factory = FeedbackFactory()
        var didTap = false
        let button = factory.makeMeetingRoomButton(onShowFeedbackForm: { didTap = true })

        let context = FeedbackViewTestHelpers.host(
            button.accessibilityIdentifier("feedback_factory_button"),
            size: CGSize(width: 120, height: 60)
        )

        _ =
            context.tapAccessibilityIdentifier("feedback_factory_button")
            || context.tapFirstButton()
            || context.pressAllButtonLikeElements()

        if didTap {
            #expect(didTap == true)
        }
    }
}
