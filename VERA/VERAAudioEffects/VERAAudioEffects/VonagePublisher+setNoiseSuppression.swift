//
//  Created by Vonage on 12/3/26.
//

import Foundation
import OpenTok
import VERADomain

extension VERAPublisher {
    public func setNoiseSuppression(enabled: Bool) throws {

        removeAudioTransformer(NoiseSuppression.key)

        if enabled {
            let params = NoiseSuppression().params()

            let vonageTransformer = try transformerFactory.makeAudioTransformer(
                for: NoiseSuppression.key,
                params: params)

            addAudioTransformer(vonageTransformer)
        }
    }
}
