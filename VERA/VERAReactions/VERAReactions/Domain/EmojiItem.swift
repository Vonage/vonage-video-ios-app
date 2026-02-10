//
//  EmojiItem.swift
//  VERAReactions
//

import Foundation

/// Represents a single emoji for display in the reactions grid
///
/// Contains the emoji character and its accessible name for VoiceOver support.
///
/// ## Usage
/// ```swift
/// let thumbsUp = EmojiItem(emoji: "👍", name: "thumbs up")
/// ```
///
/// ## Properties
/// - `id`: Unique identifier (auto-generated UUID)
/// - `emoji`: The emoji character to display
/// - `name`: Human-readable name for accessibility
public struct EmojiItem: Identifiable, Equatable, Hashable {
    /// Unique identifier for the emoji
    public let id: UUID
    
    /// The emoji character to display
    public let emoji: String
    
    /// Human-readable name used for accessibility labels
    public let name: String
    
    /// Creates a new emoji item
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - emoji: The emoji character (e.g., "👍")
    ///   - name: Accessible name (e.g., "thumbs up")
    public init(id: UUID = UUID(), emoji: String, name: String) {
        self.id = id
        self.emoji = emoji
        self.name = name
    }
}

// MARK: - Sample Data

extension EmojiItem {
    
    public static let defaultEmojis: [EmojiItem] = [
        EmojiItem(emoji: "👍", name: "thumbs up"),
        EmojiItem(emoji: "👎", name: "thumbs down"),
        EmojiItem(emoji: "👋", name: "wave"),
        EmojiItem(emoji: "👏", name: "clapping"),
        EmojiItem(emoji: "🚀", name: "rocket"),
        EmojiItem(emoji: "🎉", name: "party"),
        EmojiItem(emoji: "🙏", name: "praying"),
        EmojiItem(emoji: "💪", name: "strong"),
        EmojiItem(emoji: "❤️", name: "heart"),
        EmojiItem(emoji: "😭", name: "crying"),
        EmojiItem(emoji: "😮", name: "surprised"),
        EmojiItem(emoji: "😂", name: "laughing")
    ]
}
