//
//  EmojiPickerViewFactory.swift
//  VERAReactions
//

import SwiftUI

/// Configuration for creating an EmojiPickerView
///
/// Use this struct to customize the emoji picker appearance and behavior.
/// Provides preset configurations for common use cases.
///
/// ## Usage
/// ```swift
/// // Use default configuration
/// let picker = EmojiPickerViewFactory.make(configuration: .default) { emoji in
///     print("Selected: \(emoji.emoji)")
/// }
///
/// // Use custom configuration
/// let config = EmojiPickerConfiguration(
///     emojis: myCustomEmojis,
///     showsHighlight: true,
///     highlightDuration: 0.2
/// )
/// let customPicker = EmojiPickerViewFactory.make(configuration: config) { emoji in
///     print("Selected: \(emoji.emoji)")
/// }
/// ```
public struct EmojiPickerConfiguration {
    /// The emojis to display in the picker
    public let emojis: [EmojiItem]

    /// Whether to show highlight animation on tap
    public let showsHighlight: Bool

    /// Duration of the highlight animation in seconds
    public let highlightDuration: Double

    /// Creates a new emoji picker configuration
    /// - Parameters:
    ///   - emojis: The emojis to display
    ///   - showsHighlight: Whether to show highlight animation on tap (default: true)
    ///   - highlightDuration: Duration of highlight animation in seconds (default: 0.15)
    public init(
        emojis: [EmojiItem],
        showsHighlight: Bool = true,
        highlightDuration: Double = EmojiItemConstants.highlightDuration
    ) {
        self.emojis = emojis
        self.showsHighlight = showsHighlight
        self.highlightDuration = highlightDuration
    }
}

// MARK: - Preset Configurations

extension EmojiPickerConfiguration {
    /// Default configuration with standard emoji set and highlight enabled
    public static var `default`: EmojiPickerConfiguration {
        EmojiPickerConfiguration(
            emojis: EmojiItem.defaultEmojis,
            showsHighlight: true,
            highlightDuration: EmojiItemConstants.highlightDuration
        )
    }
}

/// Factory for creating EmojiPickerView instances
///
/// Provides a centralized way to create emoji pickers with various configurations.
///
/// ## Usage
/// ```swift
/// // Create with default configuration
/// EmojiPickerViewFactory.make(configuration: .default) { emoji in
///     print("Selected: \(emoji.emoji)")
/// }
///
/// // Create with custom emojis
/// let config = EmojiPickerConfiguration(emojis: myEmojis)
/// EmojiPickerViewFactory.make(configuration: config) { emoji in
///     handleSelection(emoji)
/// }
/// ```
public enum EmojiPickerViewFactory {
    /// Creates an EmojiPickerView with the specified configuration
    /// - Parameters:
    ///   - configuration: The configuration to use for the picker
    ///   - onEmojiSelected: Callback triggered when an emoji is selected
    /// - Returns: A configured EmojiPickerView
    public static func make(
        configuration: EmojiPickerConfiguration,
        onEmojiSelected: @escaping (EmojiItem) -> Void
    ) -> EmojiPickerView {
        EmojiPickerView(
            emojis: configuration.emojis,
            onEmojiSelected: onEmojiSelected
        )
    }

    /// Creates a default EmojiPickerView with standard emoji set
    /// - Parameter onEmojiSelected: Callback triggered when an emoji is selected
    /// - Returns: A default configured EmojiPickerView
    public static func makeDefault(
        onEmojiSelected: @escaping (EmojiItem) -> Void
    ) -> EmojiPickerView {
        make(configuration: .default, onEmojiSelected: onEmojiSelected)
    }
}

// MARK: - Previews

#Preview("Factory - Default") {
    EmojiPickerViewFactory.make(configuration: .default) { emoji in
        print("Selected: \(emoji.emoji)")
    }
    .padding()
}

#Preview("Factory - Custom Emojis") {
    let customConfig = EmojiPickerConfiguration(
        emojis: [
            EmojiItem(emoji: "🎉", name: "party"),
            EmojiItem(emoji: "🔥", name: "fire"),
            EmojiItem(emoji: "💯", name: "hundred"),
        ]
    )

    EmojiPickerViewFactory.make(configuration: customConfig) { emoji in
        print("Selected: \(emoji.emoji)")
    }
    .padding()
}
