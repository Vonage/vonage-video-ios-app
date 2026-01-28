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

        // Guardar el estado actual de video
        let wasPublishingVideo = self.publishVideo

        // Pausar video temporalmente para cambiar transformer
        if wasPublishingVideo {
            self.publishVideo = false
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
                otVideoTransformer: backgroundBlurTransformer)

            self.addVideoTransformer(vonageVideoTransformer)
        }

        // Reanudar video después de un breve delay
        if wasPublishingVideo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.publishVideo = true
            }
        }
    }
}
