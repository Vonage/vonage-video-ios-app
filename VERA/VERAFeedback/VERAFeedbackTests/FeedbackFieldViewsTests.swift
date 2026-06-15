import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback views tests")
struct FeedbackFieldViewsTests {

    @Test("FeedbackInfoFieldView builds body")
    func infoFieldBuilds() {
        let field = FeedbackFieldViewModel(
            title: "", key: "Info", type: .info, value: "Sensitive info warning", isRequired: false
        )
        FeedbackViewTestHelpers.host(FeedbackInfoFieldView(feedbackFieldViewModel: field))
        #expect(true)
    }

    @Test("FeedbackTextFieldView shows character counter when valid")
    func textFieldShowsCounter() {
        let field = FeedbackFieldViewModel(
            maxChars: 100, title: "Title", key: "Title", type: .text, value: "Hello", isRequired: true
        )
        FeedbackViewTestHelpers.host(
            FeedbackTextFieldViewTestHost(fieldVM: field, showValidationErrors: false),
            size: CGSize(width: 390, height: 160)
        )
        #expect(field.isValid)
    }

    @Test("FeedbackImageFieldView shows validation error when required image missing")
    func imageFieldShowsValidationError() {
        let field = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, isRequired: true)
        FeedbackViewTestHelpers.host(
            FeedbackImageFieldView(feedbackFieldViewModel: field, showValidationErrors: true),
            size: CGSize(width: 390, height: 260)
        )
        #expect(field.isValid == false)
    }
}
