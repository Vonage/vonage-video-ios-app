//
//  Created by Vonage on 18/05/2026.
//

import Foundation
import VERADomain

extension VERAPublisher {
    /// Applies a ``VideoEffect`` to the publisher, replacing any previously active effect.
    ///
    /// This is the single entry-point for all background effects.
    /// Calling it with `.none` clears both blur and background-replacement transformers.
    ///
    /// - Parameter effect: The effect to apply.
    public func applyVideoEffect(_ effect: VideoEffect) throws {
        removeTransformer(BackgroundBlur.key)
        removeTransformer(BackgroundReplacement.key)

        switch effect {
        case .none:
            break
        case .blurLow, .blurHigh:
            guard let level = effect.blurLevel else { return }
            let params = try BackgroundBlur().params(blurLevel: level)
            let transformer = try transformerFactory.makeVideoTransformer(
                for: BackgroundBlur.key,
                params: params)
            addVideoTransformer(transformer)
        case .backgroundImage(_, let path):
            let params = try BackgroundReplacement().params(imagePath: path)
            let transformer = try transformerFactory.makeVideoTransformer(
                for: BackgroundReplacement.key,
                params: params)
            addVideoTransformer(transformer)
        }
    }
}
