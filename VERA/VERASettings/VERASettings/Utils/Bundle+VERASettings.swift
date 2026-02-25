//
//  Created by Vonage on 25/2/26.
//

import Foundation

/// Provides the resource bundle for the VERASettings framework.
extension Bundle {
    /// The bundle associated with the VERASettings module.
    public static var veraSettings: Bundle { Bundle(for: VERASettingsBundleToken.self) }
}

private final class VERASettingsBundleToken {}
