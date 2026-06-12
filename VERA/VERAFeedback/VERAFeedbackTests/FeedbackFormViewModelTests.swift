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
}
