//
//  Created by Vonage on 10/2/26.
//

import Foundation

/// A reaction received from a participant during a call.
///
/// Represents an emoji reaction sent by a call participant,
/// including metadata about when it was sent.
public struct EmojiReaction: Identifiable, Equatable, Sendable {
    /// Unique identifier for the reaction.
    public let id: UUID

    /// Display name of the participant who sent the reaction.
    public let participantName: String

    /// The emoji character.
    public let emoji: String

    /// Timestamp when the reaction was sent.
    public let time: Date

    /// Whether this reaction was sent by the local user.
    public let isMe: Bool

    /// Creates a new reaction.
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - emoji: The emoji character.
    ///   - time: When the reaction was sent. Defaults to now.
    public init(
        id: UUID = UUID(),
        participantName: String,
        emoji: String,
        time: Date = Date(),
        isMe: Bool = false
    ) {
        self.id = id
        self.participantName = participantName
        self.emoji = emoji
        self.time = time
        self.isMe = isMe
    }
}
