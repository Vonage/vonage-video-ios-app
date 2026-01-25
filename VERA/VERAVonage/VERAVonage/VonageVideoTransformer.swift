//
//  Created by Vonage on 23/1/26.
//

import Foundation
import OpenTok

public class VonageVideoTransformer {
    public let key: String
    public let otVideoTransformer: OTVideoTransformer

    public init(key: String, otVideoTransformer: OTVideoTransformer) {
        self.key = key
        self.otVideoTransformer = otVideoTransformer
    }
}
