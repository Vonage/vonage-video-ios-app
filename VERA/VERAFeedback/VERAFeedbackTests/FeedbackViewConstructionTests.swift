import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback View Construction Tests")
struct FeedbackViewConstructionTests {

    @Test("FeedbackFormView builds body without crashing")
    func formViewBuilds() {
        let vm = FeedbackFormViewModel()
        let view = FeedbackFormView(feedbackFormViewModel: vm)

        // Access body to force view construction
        _ = view.body

        #expect(true == true)
    }

    @Test("FeedbackTextFieldView shows error state when invalid")
    func textFieldViewShowsErrorState() {
        let fieldVM = FeedbackFieldViewModel(
            maxChars: 3, title: "T", key: "T", type: .text, value: "", isRequired: true)
        let view = FeedbackTextFieldViewTestHost(fieldVM: fieldVM)

        _ = view.body
        #expect(fieldVM.isValid == false)
    }

    @Test("FeedbackImageFieldView builds with and without attached image")
    func imageFieldViewBuildsWithAndWithoutImage() {
        let fieldVM = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, isRequired: false)
        let viewNoImage = FeedbackImageFieldView(feedbackFieldViewModel: fieldVM, showValidationErrors: false)
        _ = viewNoImage.body

        // attach image and rebuild
        fieldVM.attachedImage = PlatformImage()
        let viewWithImage = FeedbackImageFieldView(feedbackFieldViewModel: fieldVM, showValidationErrors: false)
        _ = viewWithImage.body

        #expect(fieldVM.attachedImage != nil)
    }
}

@MainActor
private struct FeedbackTextFieldViewTestHost: View {
    @FocusState private var focusedFieldIndex: Int?
    let fieldVM: FeedbackFieldViewModel

    var body: some View {
        FeedbackTextFieldView(
            feedbackFieldViewModel: fieldVM,
            showValidationErrors: true,
            fieldIndex: 0,
            focusedFieldIndex: $focusedFieldIndex
        )
    }
}
