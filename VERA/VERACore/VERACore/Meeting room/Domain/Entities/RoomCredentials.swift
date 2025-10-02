//
//  Created by Vonage on 23/7/25.
//

import Foundation

public struct RoomCredentials: CustomStringConvertible {
    public let sessionId: String
    public let token: String
    public let apiKey: String
    public let captionsId: String?

    public init(
        sessionId: String,
        token: String,
        apiKey: String,
        captionsId: String? = nil
    ) {
        self.sessionId = sessionId
        self.token = token
        self.apiKey = apiKey
        self.captionsId = captionsId
    }

    public var description: String {
        """
        ApiKey:    \(apiKey)
        SessionID: \(sessionId)
        Token:     \(token)
        """
    }
}
