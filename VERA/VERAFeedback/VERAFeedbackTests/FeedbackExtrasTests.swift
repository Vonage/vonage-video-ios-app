import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback Extras Tests")
struct FeedbackExtrasTests {

    @Test("Info field is always valid and has no validation message")
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

        // image not attached -> invalid
        #expect(form.isValid == false)

        // attach an image -> valid
        form.feedbackFields[idx].attachedImage = PlatformImage()
        #expect(form.isValid == true)
    }
}
