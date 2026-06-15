import SwiftUI
import Testing

@testable import VERAFeedback

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
}
