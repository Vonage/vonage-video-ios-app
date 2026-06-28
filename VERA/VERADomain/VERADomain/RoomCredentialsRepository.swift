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

/// Response from `POST /v2/createSession`.
public struct CreateSessionResponse: Decodable {
    public let sessionId: String
    public let sessionKey: String
    public let applicationId: String

    public init(sessionId: String, sessionKey: String, applicationId: String) {
        self.sessionId = sessionId
        self.sessionKey = sessionKey
        self.applicationId = applicationId
    }
}

/// Request body for `POST /v2/createSession`.
public struct CreateSessionRequestBody: Encodable {
    let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

/// Response from `POST /v2/joinSession`.
public struct JoinSessionResponse: Decodable {
    public let token: String
    public let applicationId: String

    public init(token: String, applicationId: String) {
        self.token = token
        self.applicationId = applicationId
    }
}

/// Request body for `POST /v2/joinSession`.
public struct JoinSessionRequestBody: Encodable {
    let sessionKey: String

    public init(sessionKey: String) {
        self.sessionKey = sessionKey
    }
}

public struct RoomCredentialsRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

/// Request to join a session using an existing session key (JWT).
///
/// When a deep link contains a session key, we skip `createSession` and use the key
/// directly with `joinSession`.
public struct SessionKeyCredentialsRequest {
    public let sessionKey: String

    public init(sessionKey: String) {
        self.sessionKey = sessionKey
    }
}

public protocol RoomCredentialsRepository {
    func getRoomCredentials(_ request: RoomCredentialsRequest) async throws -> RoomCredentialsResponse
    func getCredentialsFromSessionKey(_ request: SessionKeyCredentialsRequest) async throws -> RoomCredentialsResponse
}
