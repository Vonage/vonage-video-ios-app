//
//  Created by Vonage on 11/2/26.
//

import Foundation

/// Represents a single emoji reaction for display in the reactions grid.
///
/// Contains the emoji character and its accessible name for VoiceOver support.
/// This is the UI layer model used by `EmojiPickerView` and related components.
///
/// ## Usage
/// ```swift
/// let thumbsUp = UIEmojiReaction(emoji: "👍", nameKey: "emoji.thumbs_up")
/// ```
///
/// ## Properties
/// - `id`: Unique identifier (auto-generated UUID)
/// - `emoji`: The emoji character to display
/// - `name`: Human-readable name for accessibility (localized if using nameKey)
///
/// - SeeAlso: ``EmojiReaction`` for the domain model used in networking/persistence.
public struct UIEmojiReaction: Identifiable, Equatable, Hashable {
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

    /// Creates a new emoji reaction with a localization key.
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

    /// Creates a new emoji reaction with a direct name (not localized).
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

    public static func == (lhs: UIEmojiReaction, rhs: UIEmojiReaction) -> Bool {
        lhs.id == rhs.id && lhs.emoji == rhs.emoji
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(emoji)
    }
}

// MARK: - Sample Data

extension UIEmojiReaction {

    /// Default set of emoji reactions for the picker.
    public static let defaultEmojis: [UIEmojiReaction] = [
        UIEmojiReaction(emoji: "👍", nameKey: "emoji.thumbs_up"),
        UIEmojiReaction(emoji: "👎", nameKey: "emoji.thumbs_down"),
        UIEmojiReaction(emoji: "👋", nameKey: "emoji.wave"),
        UIEmojiReaction(emoji: "👏", nameKey: "emoji.clapping"),
        UIEmojiReaction(emoji: "🚀", nameKey: "emoji.rocket"),
        UIEmojiReaction(emoji: "🎉", nameKey: "emoji.party"),
        UIEmojiReaction(emoji: "🙏", nameKey: "emoji.praying"),
        UIEmojiReaction(emoji: "💪", nameKey: "emoji.strong"),
        UIEmojiReaction(emoji: "❤️", nameKey: "emoji.heart"),
        UIEmojiReaction(emoji: "😭", nameKey: "emoji.crying"),
        UIEmojiReaction(emoji: "😮", nameKey: "emoji.surprised"),
        UIEmojiReaction(emoji: "😂", nameKey: "emoji.laughing"),
    ]
}
