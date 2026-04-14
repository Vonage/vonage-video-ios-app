//
//  Created by Vonage on 23/7/25.
//

import Foundation

public struct SessionInfo {
    public let apiKey: String
    public let sessionId: String
    public let token: String

    public init(
        apiKey: String,
        sessionId: String,
        token: String
    ) {
        self.apiKey = apiKey
        self.sessionId = sessionId
        self.token = token
    }
}
