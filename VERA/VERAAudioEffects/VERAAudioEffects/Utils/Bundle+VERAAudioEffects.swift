//
//  Created by Vonage on 12/3/26.
//

import Foundation

/// Provides the resource bundle for the VERAAudioEffects framework.
extension Bundle {
    /// The bundle associated with the VERAAudioEffects module.
    public static var veraAudioEffects: Bundle { Bundle(for: VERAAudioEffectsBundleToken.self) }
}

private final class VERAAudioEffectsBundleToken {}
