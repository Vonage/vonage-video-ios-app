//
//  Created by Vonage on 16/02/2026.
//

import Foundation

/// A single floating emoji to be rendered on screen.
///
/// Contains the emoji string, a unique identity for `ForEach`,
/// and a random horizontal position for visual variety.
public struct UIFloatingEmoji: Identifiable {
    /// Unique identifier for SwiftUI diffing.
    public let id: UUID

    /// The name of the participant who sent the reaction.
    public let participantName: String

    /// Whether this reaction was sent by the local user.
    public let isMe: Bool

    /// The emoji character to display.
    public let emoji: String

    /// Normalized horizontal position (0.0–1.0) within the overlay.
    public let horizontalPosition: CGFloat

    /// Timestamp when this floating emoji was created.
    public let createdAt: Date

    /// Creates a floating emoji from a domain reaction.
    /// - Parameter reaction: The incoming emoji reaction.
    init(reaction: EmojiReaction) {
        self.id = reaction.id
        self.participantName = reaction.participantName
        self.isMe = reaction.isMe
        self.emoji = reaction.emoji
        self.horizontalPosition = CGFloat.random(in: 0.15...0.85)
        self.createdAt = Date()
    }
}
