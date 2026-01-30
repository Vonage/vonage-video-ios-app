//
//  Created by Vonage on 25/1/26.
//

import Foundation
import OpenTok
import VERADomain
import VERAVonage

extension VERAPublisher {
    public func setBackgroundBlur(blurLevel: BlurLevel) throws {

        removeTransformer(BackgroundBlur.key)

        if blurLevel != .none {
            let params = try BackgroundBlur().params(blurLevel: blurLevel)

            let vonageTransformer = try transformerFactory.makeTransformer(
                for: BackgroundBlur.key,
                params: params)

            addVideoTransformer(vonageTransformer)
        }
    }
}
