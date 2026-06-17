import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback hosted view tests")
struct FeedbackHostedViewTests {

    @Test("FeedbackView hosts compact and regular layouts")
    func feedbackViewHostsBothLayouts() {
        let viewModel = FeedbackFormViewModel()

        FeedbackViewTestHelpers.host(
            FeedbackView(feedbackFormViewModel: viewModel)
                .environment(\.horizontalSizeClass, .compact)
        )

        FeedbackViewTestHelpers.host(
            FeedbackView(feedbackFormViewModel: viewModel)
                .environment(\.horizontalSizeClass, .regular),
            size: CGSize(width: 1024, height: 900)
        )

        #expect(true)
    }

    @Test("FeedbackFormView hosts filled and validation states")
    func feedbackFormViewHostsStates() {
        let emptyViewModel = FeedbackFormViewModel()
        FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: emptyViewModel))

        let validationViewModel = FeedbackFormViewModel()
        validationViewModel.showValidationErrors = true
        FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: validationViewModel))

        let filledViewModel = FeedbackFormViewModel()
        FeedbackTestHelpers.fillRequiredTextFields(in: filledViewModel)
        FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: filledViewModel))

        #expect(true)
    }

    @Test("FeedbackTextFieldView hosts valid and error states")
    func textFieldViewHostsStates() {
        let validField = FeedbackFieldViewModel(
            maxChars: 100, title: "Title", key: "Title", type: .text, value: "Joining a call", isRequired: true
        )
        FeedbackViewTestHelpers.host(
            FeedbackTextFieldViewHost(field: validField, showValidationErrors: false),
            size: CGSize(width: 390, height: 160)
        )

        let errorField = FeedbackFieldViewModel(
            maxChars: 100, title: "Name", key: "Name", type: .text, value: "", isRequired: true
        )
        FeedbackViewTestHelpers.host(
            FeedbackTextFieldViewHost(field: errorField, showValidationErrors: true),
            size: CGSize(width: 390, height: 180)
        )

        #expect(errorField.isValid == false)
    }

    @Test("FeedbackImageFieldView hosts empty and preview states")
    func imageFieldViewHostsStates() {
        let emptyField = FeedbackFieldViewModel(
            title: "", key: "Image", type: .image,
            value: "A screenshot will help us better understand the issue. (optional)",
            isRequired: false
        )
        FeedbackViewTestHelpers.host(
            FeedbackImageFieldView(feedbackFieldViewModel: emptyField, showValidationErrors: false),
            size: CGSize(width: 390, height: 260)
        )

        let previewField = FeedbackFieldViewModel(
            title: "", key: "Image", type: .image,
            value: "A screenshot will help us better understand the issue. (optional)",
            isRequired: false
        )
        previewField.attachedImage = FeedbackTestHelpers.makeTestImage()

        FeedbackViewTestHelpers.host(
            FeedbackImageFieldView(feedbackFieldViewModel: previewField, showValidationErrors: false),
            size: CGSize(width: 390, height: 420)
        )

        #expect(previewField.attachedImage != nil)
    }

    @Test("FeedbackSheetContent hosts without crashing")
    func sheetContentHosts() {
        FeedbackViewTestHelpers.host(FeedbackSheetContent())
        #expect(true)
    }
}

@MainActor
private struct FeedbackTextFieldViewHost: View {
    @FocusState private var focusedFieldIndex: Int?
    let field: FeedbackFieldViewModel
    let showValidationErrors: Bool

    var body: some View {
        FeedbackTextFieldView(
            feedbackFieldViewModel: field,
            showValidationErrors: showValidationErrors,
            fieldIndex: 0,
            focusedFieldIndex: $focusedFieldIndex
        )
        .padding()
        .background(Color.feedbackFormBackground)
    }
}
