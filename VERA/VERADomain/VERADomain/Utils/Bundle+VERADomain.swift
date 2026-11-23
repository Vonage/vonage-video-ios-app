//
//  Created by Vonage on 23/11/26.
//

import Foundation

/// Provides the resource bundle for the `VERADomain` framework.
extension Bundle {
    /// The bundle associated with the `VERADomain` module.
    public static var veraDomain: Bundle {
        #if SWIFT_PACKAGE
            return .module
        #else
            return Bundle(for: VERADomainBundleToken.self)
        #endif
    }
}

/// Private token class used to locate the VERADomain bundle.
private final class VERADomainBundleToken {}
