//
//  Created by Vonage on 25/2/26.
//

import Foundation

/// Provides the resource bundle for the `VERASettings`  framework.
extension Bundle {
    /// The bundle associated with the `VERASettings`  module.
    public static var veraSettings: Bundle { Bundle(for: VERASettingsBundleToken.self) }
}

/// Private token class used to locate the VERASettings bundle.
private final class VERASettingsBundleToken {}

// MARK: - String Localization

extension String {
    /// Returns the localized string from the VERASettings bundle.
    var localized: String {
        localized(bundle: .veraSettings)
    }
    
    /// Returns the localized string with format arguments.
    ///
    /// - Parameter args: Format arguments to substitute in the localized string.
    /// - Returns: The formatted localized string.
    func localized(args: CVarArg... ) -> String {
        return String(format: localized, args)
    }
}
