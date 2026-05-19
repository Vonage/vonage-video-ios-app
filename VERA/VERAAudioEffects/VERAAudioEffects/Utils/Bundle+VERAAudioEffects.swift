//
//  Created by Vonage on 12/3/26.
//

import Foundation

/// Provides the resource bundle for the VERAAudioEffects framework.
extension Bundle {
    /// The bundle associated with the VERAAudioEffects module.
    public static var veraAudioEffects: Bundle {
        #if SWIFT_PACKAGE
            return .module
        #else
            return Bundle(for: VERAAudioEffectsBundleToken.self)
        #endif
    }
}

private final class VERAAudioEffectsBundleToken {}
