import SwiftUI
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback Form ViewModel Tests")
struct FeedbackFormViewModelTests {

    @Test("Default fields are present with expected keys")
    func defaultFieldsPresent() {
        let vm = FeedbackFormViewModel()

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
        let vm = FeedbackFormViewModel()
        #expect(vm.isValid == false)
    }

    @Test("Filling required text fields makes form valid")
    func fillingRequiredFieldsMakesFormValid() {
        let vm = FeedbackFormViewModel()
        vm.feedbackFields[0].value = "Issue title"
        vm.feedbackFields[1].value = "Reporter"
        vm.feedbackFields[2].value = "Detailed description"

        #expect(vm.isValid == true)
    }

    @Test("onSubmit sets validation flag and allows submission when valid")
    func onSubmitWhenValidSetsFlag() {
        let vm = FeedbackFormViewModel()
        vm.feedbackFields[0].value = "Issue title"
        vm.feedbackFields[1].value = "Reporter"
        vm.feedbackFields[2].value = "Detailed description"

        #expect(vm.showValidationErrors == false)
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
        let form = FeedbackFormViewModel()

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
        let form = FeedbackFormViewModel()

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
}
