import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback View Construction Tests")
struct FeedbackViewConstructionTests {

    @Test("FeedbackSheetContent builds body")
    func sheetContentBuilds() {
        FeedbackViewTestHelpers.host(
            FeedbackSheetContent(
                feedbackReportUseCase: DefaultFeedbackReportUseCase(
                    feedbackReportDataSource: MockFeedbackReportDataSource()
                )
            )
        )
        #expect(true)
    }

    @Test("FeedbackFormView builds body without crashing")
    func formViewBuilds() {
        let vm = FeedbackTestHelpers.makeFormViewModel()
        let view = FeedbackFormView(feedbackFormViewModel: vm)

        // Access body to force view construction
        _ = view.body

        #expect(true)
    }

    @Test("FeedbackTextFieldView shows error state when invalid")
    func textFieldViewShowsErrorState() {
        let fieldVM = FeedbackFieldViewModel(
            maxChars: 3, title: "T", key: "T", type: .text, value: "", isRequired: true
        )
        let view = FeedbackTextFieldViewTestHost(fieldVM: fieldVM, showValidationErrors: true)
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

    @Test("FeedbackFormView hosts success and loading states")
    func feedbackFormViewHostsSuccessAndLoadingStates() {
        let successViewModel = FeedbackTestHelpers.makeFormViewModel()
        successViewModel.feedbackResult = FeedbackReportDataSourceResponse(
            message: "Report submitted",
            ticketUrl: "https://example.com/ticket/42",
            screenshotIncluded: true
        )
        FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: successViewModel))

        let loadingViewModel = FeedbackTestHelpers.makeFormViewModel()
        loadingViewModel.isLoading = true
        FeedbackViewTestHelpers.host(FeedbackFormView(feedbackFormViewModel: loadingViewModel))

        #expect(successViewModel.feedbackResult != nil)
        #expect(loadingViewModel.isLoading == true)
    }

    @Test("FeedbackSheetContent builds with session debug provider")
    func sheetContentBuildsWithSessionDebugProvider() {
        FeedbackViewTestHelpers.host(
            FeedbackSheetContent(
                feedbackReportUseCase: DefaultFeedbackReportUseCase(
                    feedbackReportDataSource: MockFeedbackReportDataSource()
                ),
                sessionDebugInfoProvider: {
                    FeedbackSessionDebugInfo(sessionId: "session-from-provider")
                }
            )
        )
        #expect(true)
    }
}
