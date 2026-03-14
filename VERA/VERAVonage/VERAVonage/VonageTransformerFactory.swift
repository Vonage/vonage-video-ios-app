//
//  Created by Vonage on 30/1/26.
//

import Foundation
import OpenTok
import VERADomain

public final class VonageTransformerFactory: VERATransformerFactory {

    public enum Error: Swift.Error {
        case encodingError
        case videoTransformerInitializationError
        case audioTransformerInitializationError
    }

    public func makeVideoTransformer(
        for key: String,
        params: String
    ) throws -> any VERATransformer {

        guard
            let videoTransformer = OTVideoTransformer(
                name: key,
                properties: params
            )
        else { throw Error.videoTransformerInitializationError }

        return VonageTransformer(
            key: key,
            transformer: videoTransformer)
    }

    public func makeAudioTransformer(for key: String, params: String) throws -> any VERATransformer {
        guard
            let audioTransformer = OTAudioTransformer(
                name: key,
                properties: params
            )
        else { throw Error.audioTransformerInitializationError }

        return VonageTransformer(
            key: key,
            transformer: audioTransformer)
    }
}
