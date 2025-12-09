//
//  Created by Vonage on 13/10/25.
//

import Foundation

public struct VonageSignal {
    public let type: String
    public let data: String?

    public init(type: String, data: String?) {
        self.type = type
        self.data = data
    }
}
