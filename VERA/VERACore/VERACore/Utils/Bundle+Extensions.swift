//
//  Created by Vonage on 30/7/25.
//

import Foundation

extension Bundle {
    static var veraCore: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: VERACore.self)
        #endif
    }
}
