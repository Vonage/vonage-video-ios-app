//
//  Created by Vonage on 10/06/2026.
//

import Combine

class FeedbackFormViewModel: ObservableObject {

    enum Const {
        static let maxStandardFieldChars = 100
        static let maxDescriptionChars = 1000
    }

    let title = "Report issue"
    @Published var showValidationErrors = false
    @Published var feedbackFields = [
        FeedbackFieldViewModel(
            maxChars: Const.maxStandardFieldChars,
            minLineLimit: 2,
            maxLineLimit: 5,
            title: "When you noticed this issue, what where you trying to do?",
            key: "Title", type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: Const.maxStandardFieldChars,
            minLineLimit: 1,
            maxLineLimit: 5,
            title: "Tell us your name", key: "Name", type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: Const.maxDescriptionChars,
            minLineLimit: 5,
            maxLineLimit: 10,
            title: "Describe your issue", key: "Description", type: .text
        ),
        FeedbackFieldViewModel(
            title: "", key: "Info", type: .info,
            value: "Please do not include any sensitive information.",
            isRequired: false
        ),
        FeedbackFieldViewModel(
            title: "", key: "Image", type: .image,
            value: "A screenshot will help us better understand the issue. (optional)",
            isRequired: false
        ),
    ]

    init() {}

    var isValid: Bool {
        feedbackFields.allSatisfy(\.isValid)
    }

    func onSubmit() {
        showValidationErrors = true
        guard isValid else { return }
        
        // TODO: Add usecase to submit this
    }
}
