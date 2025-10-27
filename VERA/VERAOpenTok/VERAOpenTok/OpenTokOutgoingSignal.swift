//
//  Created by Vonage on 13/10/25.
//

import Foundation

public struct OutgoingSignal {
    public let type: String
    public let payload: String?

    public init(type: String, payload: String?) {
        self.type = type
        self.payload = payload
    }
}
