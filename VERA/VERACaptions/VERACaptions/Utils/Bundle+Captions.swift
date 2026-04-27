//
//  Created by Vonage on 20/2/26.
//

import Foundation

/// Marker class used to locate the VERACaptions bundle
final class VERACaptionsBundle {}

extension Bundle {
    /// The bundle containing veraCaptions resources
    public static var veraCaptions: Bundle {
        #if SWIFT_PACKAGE
            return .module
        #else
            return Bundle(for: VERACaptionsBundle.self)
        #endif
    }
}
