//
//  Created by Vonage on 10/06/2026.
//

import Foundation
import Observation
import VERACommonUI

enum FeedbackFieldType {
    case text, info, image
}

protocol FieldValidatable {
    var isValid: Bool { get }
    var validationMessage: String? { get }
}
@Observable
class FeedbackFieldViewModel: FieldValidatable {
    let maxChars: Int?
    private let titleKey: String
    var title: String { titleKey.localized(bundle: .module) }
    let key: String
    var value: String
    var attachedImage: PlatformImage?
    var type: FeedbackFieldType
    var isRequired: Bool
    private var valueWithoutWhitespaces: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(
        maxChars: Int? = nil,
        title: String,
        key: String,
        type: FeedbackFieldType,
        value: String = "",
        isRequired: Bool = true
    ) {
        self.maxChars = maxChars
        self.titleKey = title
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
                return "\(key.localized(bundle: .module)) "
                    + String(
                        localized: "is required", bundle: AppLanguageStore.shared.localizedBundle(in: .module),
                        locale: AppLanguageStore.shared.locale)
            }
            return nil
        case .text:
            var message: String?
            if isRequired, valueWithoutWhitespaces.isEmpty {
                message =
                    "\(key.localized(bundle: .module)) "
                    + String(
                        localized: "is required", bundle: AppLanguageStore.shared.localizedBundle(in: .module),
                        locale: AppLanguageStore.shared.locale)
            }
            return message
        }
    }
}

extension FeedbackFieldViewModel: Identifiable {
    var id: String { key }
}
