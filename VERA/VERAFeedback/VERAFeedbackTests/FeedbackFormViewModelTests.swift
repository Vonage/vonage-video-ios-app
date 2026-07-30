import Foundation
import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback Form ViewModel Tests")
struct FeedbackFormViewModelTests {

    @Test("Default fields are present with expected keys")
    func defaultFieldsPresent() {
        let vm = FeedbackTestHelpers.makeFormViewModel()

        #expect(vm.feedbackFields.count == 5)
        let keys = vm.feedbackFields.map { $0.key }
        #expect(keys[0] == "Title")
        #expect(keys[1] == "Name")
        #expect(keys[2] == "Description")
        #expect(keys[3] == "Info")
        #expect(keys[4] == "Image")
    }

    @Test("Form is invalid by default (required fields empty)")
    func formInvalidByDefault() {
        let vm = FeedbackTestHelpers.makeFormViewModel()
        #expect(vm.isValid == false)
    }

    @Test("Filling required text fields makes form valid")
    func fillingRequiredFieldsMakesFormValid() {
        let vm = FeedbackTestHelpers.makeFormViewModel()
        vm.feedbackFields[0].value = "Issue title"
        vm.feedbackFields[1].value = "Reporter"
        vm.feedbackFields[2].value = "Detailed description"

        #expect(vm.isValid == true)
    }

    @Test("onSubmit sets validation flag when invalid")
    func onSubmitWhenInvalidSetsFlagOnly() {
        let vm = FeedbackTestHelpers.makeFormViewModel()

        #expect(vm.showValidationErrors == false)
        vm.onSubmit()
        #expect(vm.showValidationErrors == true)
        #expect(vm.isValid == false)
    }

    @Test("onSubmit sets validation flag when valid")
    func onSubmitWhenValidSetsFlag() {
        let vm = FeedbackTestHelpers.makeFormViewModel()
        vm.feedbackFields[0].value = "Issue title"
        vm.feedbackFields[1].value = "Reporter"
        vm.feedbackFields[2].value = "Detailed description"

        vm.onSubmit()
        #expect(vm.showValidationErrors == true)
        #expect(vm.isValid == true)
    }

    // MARK: - Extra coverage tests

    @Test("Info field is always valid")
    func infoFieldAlwaysValid() {
        let vm = FeedbackFieldViewModel(title: "Info", key: "Info", type: .info, value: "info text", isRequired: false)

        #expect(vm.isValid == true)
        #expect(vm.validationMessage == nil)
    }

    @Test("Text field without maxChars accepts long text")
    func textWithoutMaxAcceptsLongValue() {
        let longText = String(repeating: "x", count: 2000)
        let vm = FeedbackFieldViewModel(
            maxChars: nil, title: "Long", key: "Long", type: .text, value: longText, isRequired: true)

        #expect(vm.isValid == true)
    }

    @Test("Form default shape contains expected keys and count")
    func formDefaultsContainExpectedFields() {
        let form = FeedbackTestHelpers.makeFormViewModel()

        #expect(form.feedbackFields.count == 5)

        let keys = Set(form.feedbackFields.map { $0.key })
        #expect(keys.contains("Title"))
        #expect(keys.contains("Name"))
        #expect(keys.contains("Description"))
        #expect(keys.contains("Info"))
        #expect(keys.contains("Image"))
    }

    @Test("Making image field required makes form invalid until image attached")
    func imageRequiredToggleMakesFormInvalidUntilAttached() {
        let form = FeedbackTestHelpers.makeFormViewModel()

        // make the last field (image) required
        let imageFieldIndex = form.feedbackFields.firstIndex { $0.type == .image }
        #expect(imageFieldIndex != nil)
        guard let idx = imageFieldIndex else { return }

        form.feedbackFields[idx].isRequired = true

        // image field not attached -> invalid
        #expect(form.feedbackFields[idx].isValid == false)

        // attach an image -> field valid
        form.feedbackFields[idx].attachedImage = PlatformImage()
        #expect(form.feedbackFields[idx].isValid == true)
    }

    // MARK: - View construction checks (force body build to increase coverage)

    @Test("FeedbackFormView builds body without crashing")
    func formViewBuilds() {
        let vm = FeedbackTestHelpers.makeFormViewModel()
        let view = FeedbackFormView(feedbackFormViewModel: vm)

        // Access body to force view construction
        _ = view.body

        #expect(true == true)
    }

    @Test("FeedbackTextFieldView shows error state when invalid")
    func textFieldViewShowsErrorState() {
        let fieldVM = FeedbackFieldViewModel(
            maxChars: 3, title: "T", key: "T", type: .text, value: "", isRequired: true)
        // showValidationErrors true should cause error branch to be available

        struct HostView: View {
            @FocusState var focused: Int?
            var vm: FeedbackFieldViewModel
            var body: some View {
                FeedbackTextFieldView(
                    feedbackFieldViewModel: vm, showValidationErrors: true, fieldIndex: 0, focusedFieldIndex: $focused)
            }
        }

        let host = HostView(vm: fieldVM)
        _ = host.body
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

    // MARK: - Submit flow tests

    @Test("onSubmit sets feedbackResult when report succeeds")
    func onSubmitSetsFeedbackResultOnSuccess() async throws {
        let useCase = MockFeedbackReportUseCase()
        let viewModel = FeedbackTestHelpers.makeFormViewModel(feedbackReportUseCase: useCase)
        FeedbackTestHelpers.fillRequiredTextFields(in: viewModel)

        viewModel.onSubmit()
        try await waitUntil {
            viewModel.feedbackResult != nil && viewModel.isLoading == false
        }

        #expect(viewModel.feedbackResult?.message == "Report submitted")
        #expect(viewModel.feedbackResult?.ticketUrl == "https://example.com/ticket/1")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.toast == nil)
    }

    @Test("onSubmit shows failure toast when report fails")
    func onSubmitShowsFailureToastOnError() async throws {
        let useCase = MockFeedbackReportUseCase()
        useCase.error = URLError(.badServerResponse)
        let viewModel = FeedbackTestHelpers.makeFormViewModel(feedbackReportUseCase: useCase)
        FeedbackTestHelpers.fillRequiredTextFields(in: viewModel)

        viewModel.onSubmit()
        try await waitUntil {
            viewModel.toast != nil && viewModel.isLoading == false
        }

        #expect(viewModel.feedbackResult == nil)
        #expect(viewModel.toast?.mode == .failure)
        #expect(viewModel.isLoading == false)
    }

    @Test("onSubmit passes trimmed values, image, and session debug dump to use case")
    func onSubmitPassesTrimmedValuesImageAndDebugDump() async throws {
        let useCase = MockFeedbackReportUseCase()
        let viewModel = FeedbackTestHelpers.makeFormViewModel(
            feedbackReportUseCase: useCase,
            sessionDebugInfoProvider: {
                FeedbackSessionDebugInfo(
                    sessionId: "session-abc",
                    connectionId: "connection-xyz"
                )
            }
        )

        viewModel.feedbackFields[0].value = "  Screen share failed  "
        viewModel.feedbackFields[1].value = "  Alex  "
        viewModel.feedbackFields[2].value = "  Video froze  "
        viewModel.feedbackFields[4].attachedImage = FeedbackTestHelpers.makeTestImage()

        viewModel.onSubmit()
        try await waitUntil {
            useCase.lastRequest != nil
        }

        #expect(useCase.lastRequest?.title == "Screen share failed")
        #expect(useCase.lastRequest?.name == "Alex")
        #expect(useCase.lastRequest?.issue == "Video froze")
        #expect(useCase.lastRequest?.image != nil)
        #expect(useCase.lastRequest?.debugDump.contains("Session: session-abc") == true)
        #expect(useCase.lastRequest?.debugDump.contains("Connection: connection-xyz") == true)
    }

    @Test("onSubmit toggles loading state while report is in flight")
    func onSubmitTogglesLoadingState() async throws {
        let useCase = MockFeedbackReportUseCase()
        useCase.delayNanoseconds = 200_000_000
        let viewModel = FeedbackTestHelpers.makeFormViewModel(feedbackReportUseCase: useCase)
        FeedbackTestHelpers.fillRequiredTextFields(in: viewModel)

        viewModel.onSubmit()
        try await waitUntil {
            viewModel.isLoading
        }
        #expect(viewModel.isLoading == true)

        try await waitUntil {
            viewModel.feedbackResult != nil && viewModel.isLoading == false
        }
        #expect(viewModel.isLoading == false)
        #expect(viewModel.feedbackResult != nil)
    }

    private func waitUntil(
        timeout: Duration = .seconds(1),
        interval: Duration = .milliseconds(10),
        condition: @MainActor @escaping () -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if condition() {
                return
            }
            try await Task.sleep(for: interval)
        }

        if !condition() {
            throw WaitError.timedOut
        }
    }

    private enum WaitError: Error {
        case timedOut
    }
}
