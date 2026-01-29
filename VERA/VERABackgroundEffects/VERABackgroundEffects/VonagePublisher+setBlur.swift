//
//  Created by Vonage on 25/1/26.
//

import Foundation
import OpenTok
import VERADomain
import VERAVonage

extension VERAPublisher {
    public func setBackgroundBlur(blurLevel: BlurLevel) throws {
        guard let self = self as? VonagePublisher else {
            throw BackgroundBlur.Error.unexpectedType
        }

        self.removeTransformer(BackgroundBlur.key)

        if blurLevel != .none {
            let params = try BackgroundBlur().params(blurLevel: blurLevel)

            guard
                let backgroundBlurTransformer = OTVideoTransformer(
                    name: BackgroundBlur.key,
                    properties: params
                )
            else { throw BackgroundBlur.Error.videoTransformerInitializationError }

            let vonageVideoTransformer = VonageVideoTransformer(
                key: BackgroundBlur.key,
                transformer: backgroundBlurTransformer)

            self.addVideoTransformer(vonageVideoTransformer)
        }
    }
}
