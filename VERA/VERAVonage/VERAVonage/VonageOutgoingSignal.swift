//
//  Created by Vonage on 13/10/25.
//

import Foundation

/// A value representing an outgoing Vonage signal to be sent over the session.
///
/// `OutgoingSignal` encapsulates a signal `type` and an optional `payload` string.
/// Use it with ``VonageSignalChannel/emitSignal(_:)`` to broadcast custom events
/// (e.g., chat messages, control commands) to peers in the session.
public struct OutgoingSignal {
    /// The signal type identifier (e.g., `"chat.message"`, `"control.muteAll"`).
    public let type: String
    /// Optional string payload to include with the signal.
    public let payload: String?

    /// Creates a new outgoing signal.
    ///
    /// - Parameters:
    ///   - type: The signal type identifier.
    ///   - payload: An optional string payload to send with the signal.
    public init(type: String, payload: String?) {
        self.type = type
        self.payload = payload
    }
}
