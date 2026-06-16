//
//  Created by Vonage on 10/06/2026.
//

import Combine

enum FeedbackFormConstants {
    static let maxStandardFieldChars = 100
    static let maxDescriptionChars = 1000
}

class FeedbackFormViewModel: ObservableObject {

    static let titleKey = String(localized: "Title")
    static let titleFieldText = String(localized: "When you noticed this issue, what were you trying to do?")
    static let nameKey = String(localized: "Name")
    static let nameFieldText = String(localized: "Tell us your name")
    static let descriptionKey = String(localized: "Description")
    static let descriptionFieldText = String(localized: "Describe your issue")
    static let infoKey = String(localized: "Info")
    static let infoFieldText = String(localized: "Please do not include any sensitive information.")
    static let imageKey = String(localized: "Image")
    static let imageFieldText = String(
        localized: "A screenshot will help us better understand the issue. (optional)")

    static let formTitle = String(localized: "Report issue")

    let title = formTitle
    @Published var showValidationErrors = false
    @Published var feedbackFields = [
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxStandardFieldChars,
            title: titleFieldText,
            key: titleKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxStandardFieldChars,
            title: nameFieldText,
            key: nameKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxDescriptionChars,
            title: descriptionFieldText,
            key: descriptionKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            title: "",
            key: infoKey,
            type: .info,
            value: infoFieldText,
            isRequired: false
        ),
        FeedbackFieldViewModel(
            title: "",
            key: imageKey,
            type: .image,
            value: imageFieldText,
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
        // TODO: Add usecase to submit the form
    }
}
