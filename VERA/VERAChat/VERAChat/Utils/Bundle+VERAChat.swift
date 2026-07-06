//
//  Created by Vonage on 18/6/26.
//

import Foundation

private final class VERAChatBundleToken {}

extension Bundle {
    public static var veraChat: Bundle {
        #if SWIFT_PACKAGE
            return .module
        #else
            return Bundle(for: VERAChatBundleToken.self)
        #endif
    }
}
