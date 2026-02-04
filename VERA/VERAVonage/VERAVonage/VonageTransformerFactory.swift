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
    }

    public func makeTransformer(
        for key: String,
        params: String
    ) throws -> any VERADomain.VERATransformer {

        guard
            let backgroundBlurTransformer = OTVideoTransformer(
                name: key,
                properties: params
            )
        else { throw Error.videoTransformerInitializationError }

        return VonageTransformer(
            key: key,
            transformer: backgroundBlurTransformer)
    }
}
