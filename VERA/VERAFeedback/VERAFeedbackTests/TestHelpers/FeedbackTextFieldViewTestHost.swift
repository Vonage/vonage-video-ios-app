//
//  Created by Vonage on 15/06/2026.
//

import SwiftUI

@testable import VERAFeedback

@MainActor
struct FeedbackTextFieldViewTestHost: View {
    @FocusState private var focusedFieldIndex: Int?
    let fieldVM: FeedbackFieldViewModel
    let showValidationErrors: Bool

    var body: some View {
        FeedbackTextFieldView(
            feedbackFieldViewModel: fieldVM,
            showValidationErrors: showValidationErrors,
            fieldIndex: 0,
            focusedFieldIndex: $focusedFieldIndex
        )
    }
}
