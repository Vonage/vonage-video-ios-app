//
//  Created by Vonage on 28/6/26.
//

import Foundation

/// Represents either a room name or a session key (JWT) used to identify and join a room.
///
/// When a user opens a deep link, the path component after `/room/` can be:
/// - A plain room name (e.g., `heart-of-gold`)
/// - A session key JWT (e.g., `******
///
/// The session key already contains room credentials, so it can skip the `createSession` step
/// and proceed directly to `joinSession`.
public enum RoomIdentifier: Equatable, Hashable, Sendable {
    /// A standard room name that requires `createSession` to obtain credentials.
    case roomName(RoomName)
    /// A session key JWT that can be used directly with `joinSession`.
    case sessionKey(String)

    /// The room name for display purposes.
    ///
    /// For `.roomName`, returns the name directly.
    /// For `.sessionKey`, attempts to extract the room name from the JWT payload.
    public var displayName: RoomName {
        switch self {
        case .roomName(let name):
            return name
        case .sessionKey(let key):
            return SessionKeyParser.extractRoomName(from: key) ?? "meeting"
        }
    }

    /// Determines whether the given string is a session key (JWT) or a room name.
    ///
    /// A JWT has three base64url-encoded segments separated by dots.
    /// - Parameter value: The string to classify.
    /// - Returns: A `RoomIdentifier` case.
    public static func from(_ value: String) -> RoomIdentifier {
        if SessionKeyParser.isSessionKey(value) {
            return .sessionKey(value)
        }
        return .roomName(value)
    }
}
