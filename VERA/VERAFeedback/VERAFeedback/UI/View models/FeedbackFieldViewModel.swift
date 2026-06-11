//
//  Created by Vonage on 10/06/2026.
//

import Combine
import UIKit

enum FeedbackFieldType {
    case text, info, image
}

protocol FieldValidatable {
    var isValid: Bool { get }
    var validationMessage: String? { get }
}
class FeedbackFieldViewModel: ObservableObject, FieldValidatable {
    let maxChars: Int?
    let minLineLimit: Int?
    let maxLineLimit: Int?
    let title: String
    let key: String
    @Published var value: String
    @Published var attachedImage: UIImage?
    var type: FeedbackFieldType
    var isRequired: Bool
    private var valueWithoutWhitespaces: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(
        maxChars: Int? = nil,
        minLineLimit: Int? = nil,
        maxLineLimit: Int? = nil,
        title: String,
        key: String,
        type: FeedbackFieldType,
        value: String = "",
        isRequired: Bool = true
    ) {
        self.maxChars = maxChars
        self.minLineLimit = minLineLimit
        self.maxLineLimit = maxLineLimit
        self.title = title
        self.key = key
        self.type = type
        self.value = value
        self.isRequired = isRequired
    }

    var isValid: Bool {
        switch type {
        case .info:
            return true
        case .image:
            return !isRequired || attachedImage != nil
        case .text:
            if let maxChars, value.count > maxChars {
                return false
            }
            if isRequired {
                return !valueWithoutWhitespaces.isEmpty
            }
            return true
        }
    }

    var validationMessage: String? {
        switch type {
        case .info:
            return nil
        case .image:
            if isRequired, attachedImage == nil {
                return "\(key) " + String(localized: "is required")
            }
            return nil
        case .text:
            var message: String?
            if isRequired, valueWithoutWhitespaces.isEmpty {
                message = "\(key) " + String(localized: "is required")
            }
            return message
        }
    }
}

extension FeedbackFieldViewModel: Identifiable {
    var id: String { key }
}
