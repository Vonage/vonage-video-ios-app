import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback form focus navigation tests")
struct FeedbackFormFocusNavigationTests {

    private let defaultTextFieldIndices = [0, 1, 2]

    @Test("textFieldIndices returns only text field positions")
    func textFieldIndicesReturnsTextFieldsOnly() {
        let viewModel = FeedbackTestHelpers.makeFormViewModel()
        let fields = viewModel.feedbackFields
        #expect(FeedbackFormFocusNavigation.textFieldIndices(in: fields) == [0, 1, 2])
    }

    @Test("isFirstTextFieldFocused is true only on the first text field")
    func isFirstTextFieldFocused() {
        #expect(
            FeedbackFormFocusNavigation.isFirstTextFieldFocused(
                focusedFieldIndex: nil, textFieldIndices: defaultTextFieldIndices) == false)
        #expect(
            FeedbackFormFocusNavigation.isFirstTextFieldFocused(
                focusedFieldIndex: 0, textFieldIndices: defaultTextFieldIndices) == true)
        #expect(
            FeedbackFormFocusNavigation.isFirstTextFieldFocused(
                focusedFieldIndex: 1, textFieldIndices: defaultTextFieldIndices) == false)
    }

    @Test("isLastTextFieldFocused is true only on the last text field")
    func isLastTextFieldFocused() {
        #expect(
            FeedbackFormFocusNavigation.isLastTextFieldFocused(
                focusedFieldIndex: nil, textFieldIndices: defaultTextFieldIndices) == false)
        #expect(
            FeedbackFormFocusNavigation.isLastTextFieldFocused(
                focusedFieldIndex: 2, textFieldIndices: defaultTextFieldIndices) == true)
        #expect(
            FeedbackFormFocusNavigation.isLastTextFieldFocused(
                focusedFieldIndex: 1, textFieldIndices: defaultTextFieldIndices) == false)
    }

    @Test("focusPrevious moves to the prior text field or returns nil")
    func focusPrevious() {
        #expect(
            FeedbackFormFocusNavigation.focusPrevious(
                focusedFieldIndex: nil, textFieldIndices: defaultTextFieldIndices) == nil)
        #expect(
            FeedbackFormFocusNavigation.focusPrevious(
                focusedFieldIndex: 0, textFieldIndices: defaultTextFieldIndices) == nil)
        #expect(
            FeedbackFormFocusNavigation.focusPrevious(
                focusedFieldIndex: 1, textFieldIndices: defaultTextFieldIndices) == 0)
        #expect(
            FeedbackFormFocusNavigation.focusPrevious(
                focusedFieldIndex: 2, textFieldIndices: defaultTextFieldIndices) == 1)
        #expect(
            FeedbackFormFocusNavigation.focusPrevious(
                focusedFieldIndex: 99, textFieldIndices: defaultTextFieldIndices) == nil)
    }

    @Test("focusNext moves to the next text field or returns nil")
    func focusNext() {
        #expect(
            FeedbackFormFocusNavigation.focusNext(
                focusedFieldIndex: nil, textFieldIndices: defaultTextFieldIndices) == nil)
        #expect(
            FeedbackFormFocusNavigation.focusNext(
                focusedFieldIndex: 2, textFieldIndices: defaultTextFieldIndices) == nil)
        #expect(
            FeedbackFormFocusNavigation.focusNext(
                focusedFieldIndex: 0, textFieldIndices: defaultTextFieldIndices) == 1)
        #expect(
            FeedbackFormFocusNavigation.focusNext(
                focusedFieldIndex: 1, textFieldIndices: defaultTextFieldIndices) == 2)
        #expect(
            FeedbackFormFocusNavigation.focusNext(
                focusedFieldIndex: 99, textFieldIndices: defaultTextFieldIndices) == nil)
    }
}
