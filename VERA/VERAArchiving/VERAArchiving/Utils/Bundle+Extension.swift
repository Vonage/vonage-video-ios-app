//
//  Created by Vonage on 8/1/26.
//

import Foundation

final class VERAArchiving {}

extension Bundle {
    static var veraArchiving: Bundle {
        #if SWIFT_PACKAGE
            return .module
        #else
            return Bundle(for: VERAArchiving.self)
        #endif
    }
}
