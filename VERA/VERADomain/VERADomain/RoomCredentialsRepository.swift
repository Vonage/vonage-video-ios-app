//
//  Created by Vonage on 4/8/25.
//

import Foundation

public struct RoomCredentialsResponse: CustomStringConvertible {
    public let sessionId: String
    public let token: String
    public let apiKey: String
    public let sessionKey: String
    public let captionsId: String?

    public init(
        sessionId: String,
        token: String,
        apiKey: String,
        sessionKey: String,
        captionsId: String? = nil
    ) {
        self.sessionId = sessionId
        self.token = token
        self.apiKey = apiKey
        self.sessionKey = sessionKey
        self.captionsId = captionsId
    }

    public var description: String {
        """
        API Key:   \(apiKey)
        SessionID: \(sessionId)
        Token:     \(token)
        """
    }
}

/// Response from `POST /v2/createSessionAndJoin`.
public struct CreateSessionAndJoinResponse: Decodable {
    public let sessionId: String
    public let sessionKey: String
    public let applicationId: String
    public let token: String

    public init(sessionId: String, sessionKey: String, applicationId: String, token: String) {
        self.sessionId = sessionId
        self.sessionKey = sessionKey
        self.applicationId = applicationId
        self.token = token
    }
}

public struct CreateSessionAndJoinRequestBody: Encodable {
    let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public struct RoomCredentialsRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public protocol RoomCredentialsRepository {
    func getRoomCredentials(_ request: RoomCredentialsRequest) async throws -> RoomCredentialsResponse
}
