//
//  Created by Vonage on 23/1/26.
//

import Foundation
import OpenTok
import VERADomain

public class VonageVideoTransformer: VERAVideoTransformer {
    public let key: String
    public let transformer: AnyObject

    public init(key: String, transformer: AnyObject) {
        self.key = key
        self.transformer = transformer
    }
}
