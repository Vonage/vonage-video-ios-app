import XCTest

@testable import VERAFeedback

@MainActor
@Suite("Feedback View Models")
struct FeedbackViewModelsTests {

    @Test("Text field required empty is invalid")
    func textRequiredEmptyIsInvalid() {
        let vm = FeedbackFieldViewModel(
            maxChars: 10, title: "Title", key: "Title", type: .text, value: "", isRequired: true)

        #expect(vm.isValid == false)
        #expect(vm.validationMessage == "Title is required")
    }

    @Test("Text field required with whitespace is invalid")
    func textRequiredWhitespaceIsInvalid() {
        let vm = FeedbackFieldViewModel(
            maxChars: 10, title: "Name", key: "Name", type: .text, value: "   \n  ", isRequired: true)

        #expect(vm.isValid == false)
        #expect(vm.validationMessage == "Name is required")
    }

    @Test("Text field exceeding max chars is invalid")
    func textExceedsMaxCharsIsInvalid() {
        let vm = FeedbackFieldViewModel(maxChars: 3, title: "T", key: "T", type: .text, value: "abcd", isRequired: true)

        #expect(vm.isValid == false)
        // validationMessage for length is nil (only required shows message)
        #expect(vm.validationMessage == nil)
    }

    @Test("Optional text field empty is valid")
    func optionalTextEmptyIsValid() {
        let vm = FeedbackFieldViewModel(
            maxChars: nil, title: "Optional", key: "Optional", type: .text, value: "", isRequired: false)

        #expect(vm.isValid == true)
        #expect(vm.validationMessage == nil)
    }

    @Test("Image field required without image is invalid")
    func imageRequiredWithoutImageIsInvalid() {
        let vm = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, value: "", isRequired: true)

        #expect(vm.isValid == false)
        #expect(vm.validationMessage == "Image is required")
    }

    @Test("Image field required with image is valid")
    func imageRequiredWithImageIsValid() {
        let vm = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, value: "", isRequired: true)
        vm.attachedImage = PlatformImage()  // create an empty platform image

        #expect(vm.isValid == true)
        #expect(vm.validationMessage == nil)
    }

    @Test("Form onSubmit shows validation errors and prevents submission when invalid")
    func formOnSubmitShowsValidationErrorsWhenInvalid() {
        let form = FeedbackFormViewModel()
        // make first required field empty to force invalid
        form.feedbackFields[0].value = ""

        #expect(form.showValidationErrors == false)
        form.onSubmit()
        #expect(form.showValidationErrors == true)
        #expect(form.isValid == false)
    }

    @Test("Form is valid when all fields valid")
    func formIsValidWhenAllFieldsValid() {
        let form = FeedbackFormViewModel()
        form.feedbackFields[0].value = "some title"
        form.feedbackFields[1].value = "Reporter"
        form.feedbackFields[2].value = "A description"
        // image field is optional

        #expect(form.isValid == true)
    }
}
