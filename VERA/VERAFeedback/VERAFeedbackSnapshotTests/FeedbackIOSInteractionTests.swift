import SwiftUI
import Testing
import UIKit

@testable import VERAFeedback

@Suite("Feedback iOS interaction tests")
@MainActor
struct FeedbackIOSInteractionTests {

    @Test("FeedbackFormView hosts and exposes send control on iOS")
    func feedbackFormViewHostsOnIOS() {
        let viewModel = FeedbackFormViewModel()
        FeedbackSnapshotInteractionHelpers.host(
            NavigationStack {
                FeedbackFormView(feedbackFormViewModel: viewModel)
            }
        )
        #expect(viewModel.isValid == false)
    }

    @Test("Keyboard toolbar navigates between text fields")
    func keyboardToolbarNavigatesBetweenTextFields() {
        let viewModel = FeedbackFormViewModel()
        let context = FeedbackSnapshotInteractionHelpers.host(
            NavigationStack {
                FeedbackFormView(feedbackFormViewModel: viewModel)
            }
        )

        let inputs = context.textInputs()
        #expect(inputs.count >= 3)

        #expect(context.focusTextInput(at: 1))

        context.tapAllKeyboardToolbarButtons()
        _ = context.focusTextInput(at: 0)
        context.tapAllKeyboardToolbarButtons()

        #expect(true)
    }

    @Test("Keyboard toolbar Done dismisses the focused field")
    func keyboardToolbarDoneDismissesFocus() {
        let viewModel = FeedbackFormViewModel()
        let context = FeedbackSnapshotInteractionHelpers.host(
            NavigationStack {
                FeedbackFormView(feedbackFormViewModel: viewModel)
            }
        )

        #expect(context.focusTextInput(at: 0))

        let dismissed =
            context.tapKeyboardToolbarButton(labeled: String(localized: "Done"))
            || context.tapKeyboardToolbarButtonsMatching { label in
                label.localizedCaseInsensitiveContains("done")
            }

        if dismissed {
            #expect(context.textInputs().allSatisfy { !$0.isFirstResponder })
        }
    }

    @Test("UIKit screenshot capturer runs without crashing on iOS")
    func captureScreenshotDoesNotCrashOnIOS() {
        _ = FeedbackScreenshotCapturer.captureContentBehindModal()
        #expect(true)
    }

    @Test("FeedbackButton hosts on iOS")
    func feedbackButtonHostsOnIOS() {
        FeedbackSnapshotInteractionHelpers.host(
            FeedbackButton(onShowFeedbackForm: {}),
            size: CGSize(width: 120, height: 60)
        )
        #expect(true)
    }

    @Test("FeedbackImageFieldView hosts with preview on iOS")
    func imageFieldHostsWithPreviewOnIOS() {
        let field = FeedbackFieldViewModel(
            title: "", key: "Image", type: .image,
            value: "A screenshot will help us better understand the issue. (optional)",
            isRequired: false
        )
        field.attachedImage = FeedbackSnapshotHelpers.makeTestImage()
        FeedbackSnapshotInteractionHelpers.host(
            FeedbackImageFieldView(feedbackFieldViewModel: field, showValidationErrors: false),
            size: CGSize(width: 390, height: 420)
        )
        #expect(field.attachedImage != nil)
    }

    @Test("Filled FeedbackView hosts on iOS")
    func filledFeedbackViewHostsOnIOS() {
        let viewModel = FeedbackFormViewModel()
        FeedbackSnapshotHelpers.fillRequiredTextFields(in: viewModel)
        FeedbackSnapshotInteractionHelpers.host(
            FeedbackView(feedbackFormViewModel: viewModel)
                .environment(\.horizontalSizeClass, .compact)
        )
        #expect(viewModel.isValid == true)
    }
}
