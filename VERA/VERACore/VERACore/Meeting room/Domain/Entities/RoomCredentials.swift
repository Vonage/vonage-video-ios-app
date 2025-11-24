//
//  Created by Vonage on 23/7/25.
//

import Foundation

public struct RoomCredentials: CustomStringConvertible {
    public let sessionId: String
    public let token: String
    public let applicationId: String
    public let roomName: String
    public let captionsId: String?

    public init(
        sessionId: String,
        token: String,
        applicationId: String,
        roomName: String,
        captionsId: String? = nil
    ) {
        self.sessionId = sessionId
        self.token = token
        self.applicationId = applicationId
        self.roomName = roomName
        self.captionsId = captionsId
    }

    public var description: String {
        """
        App ID:    \(applicationId)
        SessionID: \(sessionId)
        Token:     \(token)
        Room name: \(roomName)
        """
    }
}
