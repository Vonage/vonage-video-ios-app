//
//  Created by Vonage on 10/06/2026.
//

import Combine

class FeedbackFormViewModel: ObservableObject {

    enum Constants {
        static let maxStandardFieldChars = 100
        static let maxDescriptionChars = 1000
        
        static let titleKey = String(localized: "Title")
        static let titleFieldText = String(localized: "When you noticed this issue, what where you trying to do?")
        static let nameKey = String(localized: "Name")
        static let nameFieldText = String(localized: "Tell us your name")
        static let descriptionKey = String(localized: "Description")
        static let descriptionFieldText = String(localized: "Describe your issue")
        static let infoKey = String(localized: "Info")
        static let infoFieldText = String(localized: "Please do not include any sensitive information.")
        static let imageKey = String(localized: "Image")
        static let imageFieldText = String(localized: "A screenshot will help us better understand the issue. (optional)")
        
        static let formTitle =  String(localized: "Report issue")
    }

    let title = Constants.formTitle
    @Published var showValidationErrors = false
    @Published var feedbackFields = [
        FeedbackFieldViewModel(
            maxChars: Constants.maxStandardFieldChars,
            title: Constants.titleFieldText,
            key: Constants.titleKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: Constants.maxStandardFieldChars,
            title: Constants.nameFieldText,
            key: Constants.nameKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: Constants.maxDescriptionChars,
            title: Constants.descriptionFieldText,
            key: Constants.descriptionKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            title: "",
            key: Constants.infoKey,
            type: .info,
            value: Constants.infoFieldText,
            isRequired: false
        ),
        FeedbackFieldViewModel(
            title: "",
            key: Constants.imageKey,
            type: .image,
            value: Constants.imageFieldText,
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
