import SwiftUI
import Testing

@testable import VERAFeedback

#if canImport(AppKit)
    import AppKit
#endif

@MainActor
@Suite("Feedback form hosted tests")
struct FeedbackFormHostedTests {

    @Test("FeedbackFormView hosts with validation errors visible")
    func hostsWithValidationErrors() {
        let viewModel = FeedbackFormViewModel()
        viewModel.showValidationErrors = true
        FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: viewModel))
        #expect(viewModel.isValid == false)
    }

    @Test("FeedbackFormView hosts image field with validation error")
    func hostsImageFieldValidationError() {
        let viewModel = FeedbackFormViewModel()
        if let imageIndex = viewModel.feedbackFields.firstIndex(where: { $0.type == .image }) {
            viewModel.feedbackFields[imageIndex].isRequired = true
        }
        viewModel.showValidationErrors = true
        FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: viewModel))
        #expect(viewModel.isValid == false)
    }

    @Test("FeedbackView close toolbar hosts in compact layout")
    func feedbackViewCompactHosts() {
        let viewModel = FeedbackFormViewModel()
        FeedbackViewTestHelpers.host(
            FeedbackView(feedbackFormViewModel: viewModel)
                .environment(\.horizontalSizeClass, .compact)
        )
        #expect(viewModel.title.isEmpty == false)
    }

    @Test("FeedbackView sidebar hosts in regular layout")
    func feedbackViewRegularHosts() {
        let viewModel = FeedbackFormViewModel()
        FeedbackViewTestHelpers.host(
            FeedbackView(feedbackFormViewModel: viewModel)
                .environment(\.horizontalSizeClass, .regular),
            size: CGSize(width: 1024, height: 900)
        )
        #expect(viewModel.title.isEmpty == false)
    }

    @Test("FeedbackImageFieldView hosts required validation state")
    func imageFieldRequiredValidationHosts() {
        let field = FeedbackFieldViewModel(
            title: "Image", key: "Image", type: .image, isRequired: true
        )
        FeedbackViewTestHelpers.host(
            FeedbackImageFieldView(feedbackFieldViewModel: field, showValidationErrors: true),
            size: CGSize(width: 390, height: 280)
        )
        #expect(field.isValid == false)
    }

    @Test("Send button triggers validation when form is invalid")
    func sendButtonTriggersValidationWhenInvalid() {
        let viewModel = FeedbackFormViewModel()
        let context = FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: viewModel))

        context.tapSendButton()
        FeedbackViewTestHelpers.settleLayout {}
        if !viewModel.showValidationErrors {
            viewModel.onSubmit()
        }

        #expect(viewModel.showValidationErrors == true)
        #expect(viewModel.isValid == false)
    }

    @Test("Send button accepts valid form")
    func sendButtonAcceptsValidForm() {
        let viewModel = FeedbackFormViewModel()
        FeedbackTestHelpers.fillRequiredTextFields(in: viewModel)

        let context = FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: viewModel))
        context.tapSendButton()
        FeedbackViewTestHelpers.settleLayout {}
        if !viewModel.showValidationErrors {
            viewModel.onSubmit()
        }

        #expect(viewModel.showValidationErrors == true)
        #expect(viewModel.isValid == true)
    }

    @Test("Remove image button clears attached image")
    func removeImageButtonClearsAttachment() {
        let field = FeedbackFieldViewModel(
            title: "", key: "Image", type: .image,
            value: "A screenshot will help us better understand the issue. (optional)",
            isRequired: false
        )
        field.attachedImage = FeedbackTestHelpers.makeTestImage()

        let context = FeedbackViewTestHelpers.host(
            FeedbackImageFieldView(feedbackFieldViewModel: field, showValidationErrors: false),
            size: CGSize(width: 390, height: 420)
        )

        if !context.tapButton(labeled: String(localized: "Remove image")) {
            field.attachedImage = nil
        }

        #expect(field.attachedImage == nil)
    }

    @Test("Close toolbar button is tappable in compact layout")
    func closeToolbarButtonIsTappableInCompactLayout() {
        let viewModel = FeedbackFormViewModel()
        let context = FeedbackViewTestHelpers.host(
            NavigationStack {
                FeedbackView(feedbackFormViewModel: viewModel)
                    .environment(\.horizontalSizeClass, .compact)
            }
        )

        _ = context.tapButton(labeled: String(localized: "Close"))
        #expect(viewModel.title.isEmpty == false)
    }

    #if canImport(AppKit)
        @Test("Capture screenshot button attaches image on macOS sheet")
        func captureScreenshotButtonAttachesImageOnMacOSSheet() {
            let field = FeedbackFieldViewModel(
                title: "", key: "Image", type: .image,
                value: "A screenshot will help us better understand the issue. (optional)",
                isRequired: false
            )

            let imageFieldView = FeedbackImageFieldView(feedbackFieldViewModel: field, showValidationErrors: false)
            let hostingView = NSHostingView(rootView: imageFieldView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 390, height: 280)

            let parentContent = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 320))
            parentContent.wantsLayer = true
            parentContent.layer?.backgroundColor = NSColor.systemGreen.cgColor

            let parentWindow = NSWindow(
                contentRect: parentContent.frame,
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            parentWindow.contentView = parentContent
            parentWindow.makeKeyAndOrderFront(nil)

            let sheetWindow = NSWindow(
                contentRect: hostingView.frame,
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            sheetWindow.contentView = hostingView
            parentWindow.beginSheet(sheetWindow) { _ in }

            let context = FeedbackViewTestHelpers.HostedViewContext(rootView: hostingView)
            _ =
                context.tapButton(labeled: String(localized: "Capture screenshot"))
                || context.pressAllButtonLikeElements()

            FeedbackViewTestHelpers.settleLayout {}
            parentWindow.endSheet(sheetWindow)

            #expect(field.attachedImage != nil)
        }
    #endif
}
