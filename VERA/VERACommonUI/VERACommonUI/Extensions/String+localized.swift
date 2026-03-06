//
//  Created by Vonage on 04/03/2026.
//
import Foundation

extension String {

    public func localized(bundle: Bundle = .main) -> String {
        return NSLocalizedString(
            self,
            tableName: nil,
            bundle: bundle,
            value: "",
            comment: "\(self)_comment"
        )
    }

    public func localized(args: CVarArg..., bundle: Bundle = .main) -> String {
        let format = localized(bundle: bundle)
        return String(format: format, args)
    }

    public func pluralizeIfNeeded(count: Int) -> String {
        return "^[\(count) \(self)](inflect: true)"
    }
}
