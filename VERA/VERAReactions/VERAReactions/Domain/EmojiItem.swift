//
//  Created by Vonage on 9/2/26.
//

import Foundation

/// Represents a single emoji for display in the reactions grid
///
/// Contains the emoji character and its accessible name for VoiceOver support.
///
/// ## Usage
/// ```swift
/// let thumbsUp = EmojiItem(emoji: "👍", nameKey: "emoji.thumbs_up")
/// ```
///
/// ## Properties
/// - `id`: Unique identifier (auto-generated UUID)
/// - `emoji`: The emoji character to display
/// - `name`: Human-readable name for accessibility (localized if using nameKey)
public struct EmojiItem: Identifiable, Equatable, Hashable {
    /// Unique identifier for the emoji
    public let id: UUID

    /// The emoji character to display
    public let emoji: String

    /// Localization key for the emoji name (optional)
    private let nameKey: String?

    /// Fallback name if no localization key is provided
    private let fallbackName: String

    /// Human-readable name used for accessibility labels (localized)
    public var name: String {
        if let key = nameKey {
            return String(localized: String.LocalizationValue(key), bundle: .veraReactions)
        }
        return fallbackName
    }

    /// Creates a new emoji item with a localization key
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - emoji: The emoji character (e.g., "👍")
    ///   - nameKey: Localization key for the accessible name (e.g., "emoji.thumbs_up")
    public init(id: UUID = UUID(), emoji: String, nameKey: String) {
        self.id = id
        self.emoji = emoji
        self.nameKey = nameKey
        self.fallbackName = nameKey
    }

    /// Creates a new emoji item with a direct name (not localized)
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - emoji: The emoji character (e.g., "👍")
    ///   - name: Accessible name (e.g., "thumbs up")
    public init(id: UUID = UUID(), emoji: String, name: String) {
        self.id = id
        self.emoji = emoji
        self.nameKey = nil
        self.fallbackName = name
    }

    // MARK: - Equatable & Hashable

    public static func == (lhs: EmojiItem, rhs: EmojiItem) -> Bool {
        lhs.id == rhs.id && lhs.emoji == rhs.emoji
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(emoji)
    }
}

// MARK: - Sample Data

extension EmojiItem {

    public static let defaultEmojis: [EmojiItem] = [
        EmojiItem(emoji: "👍", nameKey: "emoji.thumbs_up"),
        EmojiItem(emoji: "👎", nameKey: "emoji.thumbs_down"),
        EmojiItem(emoji: "👋", nameKey: "emoji.wave"),
        EmojiItem(emoji: "👏", nameKey: "emoji.clapping"),
        EmojiItem(emoji: "🚀", nameKey: "emoji.rocket"),
        EmojiItem(emoji: "🎉", nameKey: "emoji.party"),
        EmojiItem(emoji: "🙏", nameKey: "emoji.praying"),
        EmojiItem(emoji: "💪", nameKey: "emoji.strong"),
        EmojiItem(emoji: "❤️", nameKey: "emoji.heart"),
        EmojiItem(emoji: "😭", nameKey: "emoji.crying"),
        EmojiItem(emoji: "😮", nameKey: "emoji.surprised"),
        EmojiItem(emoji: "😂", nameKey: "emoji.laughing"),
    ]
}
