import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback View Construction Tests")
struct FeedbackViewConstructionTests {

    @Test("FeedbackFormView builds body without crashing")
    func formViewBuilds() {
        let vm = FeedbackFormViewModel()
        FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: vm))
        #expect(true)
    }

    @Test("FeedbackTextFieldView shows error state when invalid")
    func textFieldViewShowsErrorState() {
        let fieldVM = FeedbackFieldViewModel(
            maxChars: 3, title: "T", key: "T", type: .text, value: "", isRequired: true
        )
        let view = FeedbackTextFieldViewTestHost(fieldVM: fieldVM)
        FeedbackViewTestHelpers.host(view, size: CGSize(width: 390, height: 160))
        #expect(fieldVM.isValid == false)
    }

    @Test("FeedbackImageFieldView builds with and without attached image")
    func imageFieldViewBuildsWithAndWithoutImage() {
        let fieldVM = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, isRequired: false)
        FeedbackViewTestHelpers.host(
            FeedbackImageFieldView(feedbackFieldViewModel: fieldVM, showValidationErrors: false),
            size: CGSize(width: 390, height: 260)
        )

        fieldVM.attachedImage = PlatformImage()
        FeedbackViewTestHelpers.host(
            FeedbackImageFieldView(feedbackFieldViewModel: fieldVM, showValidationErrors: false),
            size: CGSize(width: 390, height: 420)
        )

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
