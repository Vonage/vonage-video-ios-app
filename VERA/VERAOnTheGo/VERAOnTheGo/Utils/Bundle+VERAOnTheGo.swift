//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// Provides the resource bundle for the `VERAOnTheGo` framework.
extension Bundle {
    /// The bundle associated with the `VERAOnTheGo` module.
    public static var veraOnTheGo: Bundle {
        #if SWIFT_PACKAGE
            return .module
        #else
            return Bundle(for: VERAOnTheGoBundleToken.self)
        #endif
    }
}

/// Private token class used to locate the VERAOnTheGo bundle.
private final class VERAOnTheGoBundleToken {}

// MARK: - String Localization

extension String {
    /// Returns the localized string from the VERAOnTheGo bundle.
    var localized: String {
        localized(bundle: .veraOnTheGo)
    }

    /// Returns the localized string with format arguments.
    ///
    /// - Parameter args: Format arguments to substitute in the localized string.
    /// - Returns: The formatted localized string.
    func localized(args: CVarArg...) -> String {
        return String(format: localized, arguments: args)
    }
}
