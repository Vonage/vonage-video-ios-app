//
//  Created by Vonage on 12/8/26.
//

import Foundation

/// Provides the resource bundle for the VERAOKTA framework.
extension Bundle {
    /// The bundle associated with the VERAOKTA module.
    public static var veraOKTA: Bundle { Bundle(for: VERAOKTABundleToken.self) }
}

private final class VERAOKTABundleToken {}
