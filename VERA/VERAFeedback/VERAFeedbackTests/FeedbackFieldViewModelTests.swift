import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback Field ViewModel Tests")
struct FeedbackFieldViewModelTests {

    @Test("Required text field empty is invalid and returns message")
    func requiredTextEmptyIsInvalid() {
        let vm = FeedbackFieldViewModel(
            maxChars: 10, title: "Title", key: "Title", type: .text, value: "", isRequired: true)

        #expect(vm.isValid == false)
        #expect(vm.validationMessage == "Title is required")
    }

    @Test("Required text field with only whitespace is invalid")
    func requiredTextWhitespaceIsInvalid() {
        let vm = FeedbackFieldViewModel(
            maxChars: 10, title: "Name", key: "Name", type: .text, value: "   \n  ", isRequired: true)

        #expect(vm.isValid == false)
        #expect(vm.validationMessage == "Name is required")
    }

    @Test("Text field exceeding max chars is invalid, validation message remains for required only")
    func textExceedingMaxCharsIsInvalid() {
        let vm = FeedbackFieldViewModel(maxChars: 3, title: "T", key: "T", type: .text, value: "abcd", isRequired: true)

        #expect(vm.isValid == false)
        #expect(vm.validationMessage == nil)
    }

    @Test("Text field exactly at max chars is valid")
    func textExactlyAtMaxIsValid() {
        let vm = FeedbackFieldViewModel(maxChars: 3, title: "T", key: "T", type: .text, value: "abc", isRequired: true)

        #expect(vm.isValid == true)
        #expect(vm.validationMessage == nil)
    }

    @Test("Optional text field empty is valid")
    func optionalTextEmptyIsValid() {
        let vm = FeedbackFieldViewModel(
            maxChars: nil, title: "Optional", key: "Optional", type: .text, value: "", isRequired: false)

        #expect(vm.isValid == true)
        #expect(vm.validationMessage == nil)
    }

    @Test("Optional text field exceeding max chars is invalid")
    func optionalTextExceedingMaxIsInvalid() {
        let vm = FeedbackFieldViewModel(
            maxChars: 3, title: "Opt", key: "Opt", type: .text, value: "abcd", isRequired: false)

        #expect(vm.isValid == false)
    }

    @Test("Image field required without image is invalid and shows message")
    func imageRequiredWithoutImageIsInvalid() {
        let vm = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, value: "", isRequired: true)

        #expect(vm.isValid == false)
        #expect(vm.validationMessage == "Image is required")
    }

    @Test("Image field required with image is valid")
    func imageRequiredWithImageIsValid() {
        let vm = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, value: "", isRequired: true)
        vm.attachedImage = PlatformImage()

        #expect(vm.isValid == true)
        #expect(vm.validationMessage == nil)
    }

    @Test("Optional image field without image is valid")
    func optionalImageWithoutImageIsValid() {
        let vm = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, value: "", isRequired: false)

        #expect(vm.isValid == true)
        #expect(vm.validationMessage == nil)
    }

    @Test("Field id equals key")
    func fieldIdEqualsKey() {
        let vm = FeedbackFieldViewModel(title: "Title", key: "MyKey", type: .text)
        #expect(vm.id == "MyKey")
    }
}
