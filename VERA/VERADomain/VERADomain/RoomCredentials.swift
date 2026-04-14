//
//  Created by Vonage on 23/7/25.
//

import Foundation

/// Domain credentials required to join an Vonage room/session.
///
/// `RoomCredentials` bundles the identifiers and token needed to establish a call,
/// plus metadata like the room name and optional captions stream identifier.
public struct RoomCredentials: CustomStringConvertible {
    /// The Vonage application (API) key associated with the session.
    public let applicationId: String
    /// The Vonage session identifier.
    public let sessionId: String
    /// The Vonage token used to authenticate and connect.
    public let token: String
    /// The human-readable room name.
    public let roomName: String
    /// Optional captions stream identifier, when captions are enabled.
    public let captionsId: String?

    /// Creates a new credentials value.
    ///
    /// - Parameters:
    ///   - sessionId: The Vonage session identifier.
    ///   - token: The Vonage token used for authentication.
    ///   - applicationId: The Vonage application (API) key.
    ///   - roomName: A human-readable room name.
    ///   - captionsId: Optional captions stream identifier.
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

    /// A human-readable summary of the credentials for logging and diagnostics.
    public var description: String {
        """
        App ID:    \(applicationId)
        SessionID: \(sessionId)
        Token:     \(token)
        Room name: \(roomName)
        """
    }
}
