import XCTest
@testable import VERAFeedback

final class FeedbackViewModelsXCTest: XCTestCase {

    func testTextFieldRequiredEmpty_isInvalid() {
        let vm = FeedbackFieldViewModel(maxChars: 10, title: "Title", key: "Title", type: .text, value: "", isRequired: true)

        XCTAssertFalse(vm.isValid)
        XCTAssertEqual(vm.validationMessage, "Title is required")
    }

    func testTextFieldWhitespace_isInvalid() {
        let vm = FeedbackFieldViewModel(maxChars: 10, title: "Name", key: "Name", type: .text, value: "   \n  ", isRequired: true)

        XCTAssertFalse(vm.isValid)
        XCTAssertEqual(vm.validationMessage, "Name is required")
    }

    func testTextFieldExceedsMaxChars_isInvalid() {
        let vm = FeedbackFieldViewModel(maxChars: 3, title: "T", key: "T", type: .text, value: "abcd", isRequired: true)

        XCTAssertFalse(vm.isValid)
        XCTAssertNil(vm.validationMessage)
    }

    func testOptionalTextEmpty_isValid() {
        let vm = FeedbackFieldViewModel(maxChars: nil, title: "Optional", key: "Optional", type: .text, value: "", isRequired: false)

        XCTAssertTrue(vm.isValid)
        XCTAssertNil(vm.validationMessage)
    }

    func testImageRequiredWithoutImage_isInvalid() {
        let vm = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, value: "", isRequired: true)

        XCTAssertFalse(vm.isValid)
        XCTAssertEqual(vm.validationMessage, "Image is required")
    }

    func testImageRequiredWithImage_isValid() {
        let vm = FeedbackFieldViewModel(title: "Image", key: "Image", type: .image, value: "", isRequired: true)
        vm.attachedImage = PlatformImage()

        XCTAssertTrue(vm.isValid)
        XCTAssertNil(vm.validationMessage)
    }

    func testFormOnSubmit_showsValidationErrorsWhenInvalid() {
        let form = FeedbackFormViewModel()
        form.feedbackFields[0].value = ""

        XCTAssertFalse(form.showValidationErrors)
        form.onSubmit()
        XCTAssertTrue(form.showValidationErrors)
        XCTAssertFalse(form.isValid)
    }

    func testFormIsValidWhenAllFieldsValid() {
        let form = FeedbackFormViewModel()
        form.feedbackFields[0].value = "some title"
        form.feedbackFields[1].value = "Reporter"
        form.feedbackFields[2].value = "A description"

        XCTAssertTrue(form.isValid)
    }
}
