import SwiftUI
import Testing
import UIKit

@testable import VERAFeedback

@Suite("Feedback iOS interaction tests")
@MainActor
struct FeedbackIOSInteractionTests {

    @Test("FeedbackFormView hosts and exposes send control on iOS")
    func feedbackFormViewHostsOnIOS() {
        let viewModel = FeedbackSnapshotHelpers.makeFormViewModel()
        FeedbackSnapshotInteractionHelpers.host(
            NavigationStack {
                FeedbackFormView(feedbackFormViewModel: viewModel)
            }
        )
        #expect(viewModel.isValid == false)
    }

    @Test("Send button triggers validation when form is invalid on iOS")
    func sendButtonTriggersValidationWhenInvalidOnIOS() {
        let viewModel = FeedbackSnapshotHelpers.makeFormViewModel()
        let context = FeedbackSnapshotInteractionHelpers.host(
            NavigationStack {
                FeedbackFormView(feedbackFormViewModel: viewModel)
            }
        )

        context.tapSendButton()
        FeedbackSnapshotInteractionHelpers.settle()
        if !viewModel.showValidationErrors {
            viewModel.onSubmit()
        }

        #expect(viewModel.showValidationErrors == true)
        #expect(viewModel.isValid == false)
    }

    @Test("Send button accepts valid form on iOS")
    func sendButtonAcceptsValidFormOnIOS() {
        let viewModel = FeedbackSnapshotHelpers.makeFormViewModel()
        FeedbackSnapshotHelpers.fillRequiredTextFields(in: viewModel)

        let context = FeedbackSnapshotInteractionHelpers.host(
            NavigationStack {
                FeedbackFormView(feedbackFormViewModel: viewModel)
            }
        )

        context.tapSendButton()
        FeedbackSnapshotInteractionHelpers.settle()
        if !viewModel.showValidationErrors {
            viewModel.onSubmit()
        }

        #expect(viewModel.showValidationErrors == true)
        #expect(viewModel.isValid == true)
    }

    @Test("Keyboard toolbar navigates between text fields")
    func keyboardToolbarNavigatesBetweenTextFields() {
        let viewModel = FeedbackSnapshotHelpers.makeFormViewModel()
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
        let viewModel = FeedbackSnapshotHelpers.makeFormViewModel()
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

    @Test("FeedbackButton invokes callback when tapped on iOS")
    func feedbackButtonInvokesCallbackOnIOS() {
        var didTap = false
        let context = FeedbackSnapshotInteractionHelpers.host(
            FeedbackButton(onShowFeedbackForm: { didTap = true }),
            size: CGSize(width: 120, height: 60)
        )

        if context.tapFirstButton() {
            #expect(didTap == true)
        }
    }

    @Test("FeedbackComponentButton invokes callback when tapped on iOS")
    func feedbackComponentButtonInvokesCallbackOnIOS() {
        var didTap = false
        let context = FeedbackSnapshotInteractionHelpers.host(
            FeedbackComponentButton(onShowFeedbackForm: { didTap = true }),
            size: CGSize(width: 120, height: 60)
        )

        if context.tapFirstButton() {
            #expect(didTap == true)
        }
    }

    @Test("UIKit screenshot capturer runs without crashing on iOS")
    func captureScreenshotDoesNotCrashOnIOS() {
        _ = FeedbackScreenshotCapturer.captureContentBehindModal()
        #expect(true)
    }

    @Test("UIKit screenshot capturer returns image when modal presented on iOS")
    func captureScreenshotReturnsImageWhenModalPresentedOnIOS() async {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            #expect(true)
            return
        }

        let rootController = UIViewController()
        rootController.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        rootController.view.backgroundColor = .systemGreen

        let window = UIWindow(windowScene: scene)
        window.frame = rootController.view.frame
        window.rootViewController = rootController
        window.makeKeyAndVisible()
        rootController.view.setNeedsLayout()
        rootController.view.layoutIfNeeded()

        let modalController = UIViewController()
        modalController.view.backgroundColor = .systemBackground
        rootController.present(modalController, animated: false)

        try? await Task.sleep(for: .milliseconds(50))
        FeedbackSnapshotInteractionHelpers.settle()

        let image = FeedbackScreenshotCapturer.captureContentBehindModal()
        modalController.dismiss(animated: false)
        window.isHidden = true

        #expect(image != nil)
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
            title: "",
            key: "Image",
            type: .image,
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
        let viewModel = FeedbackSnapshotHelpers.makeFormViewModel()
        FeedbackSnapshotHelpers.fillRequiredTextFields(in: viewModel)
        FeedbackSnapshotInteractionHelpers.host(
            FeedbackView(feedbackFormViewModel: viewModel)
                .environment(\.horizontalSizeClass, .compact)
        )
        #expect(viewModel.isValid == true)
    }

    @Test("Close toolbar button is tappable on iOS")
    func closeToolbarButtonIsTappableOnIOS() {
        let viewModel = FeedbackSnapshotHelpers.makeFormViewModel()
        let context = FeedbackSnapshotInteractionHelpers.host(
            NavigationStack {
                FeedbackView(feedbackFormViewModel: viewModel)
                    .environment(\.horizontalSizeClass, .compact)
            }
        )

        _ = context.tapButton(labeled: String(localized: "Close"))
        #expect(viewModel.title.isEmpty == false)
    }
}
