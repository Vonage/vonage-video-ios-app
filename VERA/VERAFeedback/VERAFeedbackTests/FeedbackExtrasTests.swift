import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback Extras Tests")
struct FeedbackExtrasTests {

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

        let imageFieldIndex = form.feedbackFields.firstIndex { $0.type == .image }
        #expect(imageFieldIndex != nil)
        guard let idx = imageFieldIndex else { return }

        form.feedbackFields[idx].isRequired = true
        #expect(form.feedbackFields[idx].isValid == false)

        form.feedbackFields[idx].attachedImage = PlatformImage()
        #expect(form.feedbackFields[idx].isValid == true)
    }
}
