//
//  Created by Vonage on 15/06/2026.
//

import Foundation

/// Pure focus-navigation helpers for the feedback form keyboard toolbar.
enum FeedbackFormFocusNavigation {

    static func textFieldIndices(in fields: [FeedbackFieldViewModel]) -> [Int] {
        fields.indices.filter { fields[$0].type == .text }
    }

    static func isFirstTextFieldFocused(focusedFieldIndex: Int?, textFieldIndices: [Int]) -> Bool {
        guard let focusedFieldIndex else { return false }
        return focusedFieldIndex == textFieldIndices.first
    }

    static func isLastTextFieldFocused(focusedFieldIndex: Int?, textFieldIndices: [Int]) -> Bool {
        guard let focusedFieldIndex else { return false }
        return focusedFieldIndex == textFieldIndices.last
    }

    /// Returns the previous text-field index, or `nil` when focus should not change.
    static func focusPrevious(focusedFieldIndex: Int?, textFieldIndices: [Int]) -> Int? {
        guard let focusedFieldIndex,
            let currentIndex = textFieldIndices.firstIndex(of: focusedFieldIndex),
            currentIndex > 0
        else { return nil }

        return textFieldIndices[currentIndex - 1]
    }

    /// Returns the next text-field index, or `nil` when focus should not change.
    static func focusNext(focusedFieldIndex: Int?, textFieldIndices: [Int]) -> Int? {
        guard let focusedFieldIndex,
            let currentIndex = textFieldIndices.firstIndex(of: focusedFieldIndex),
            currentIndex < textFieldIndices.count - 1
        else { return nil }

        return textFieldIndices[currentIndex + 1]
    }
}
