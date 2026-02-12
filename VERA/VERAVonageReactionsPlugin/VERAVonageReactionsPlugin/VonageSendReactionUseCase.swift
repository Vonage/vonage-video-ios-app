//
//  Created by Vonage on 11/2/26.
//

import Foundation
import VERAReactions

/// Vonage implementation of the send reaction use case.
///
/// Wraps `VonageReactionsPlugin.sendReaction(_:)` for clean UI integration
/// with `EmojiPickerView.onEmojiSelected`.
///
/// ## Usage
/// ```swift
/// let useCase = VonageSendReactionUseCase(plugin: reactionsPlugin)
///
/// EmojiPickerView(emojis: UIEmojiReaction.defaultEmojis) { emoji in
///     try? useCase(emoji.emoji)
/// }
/// ```
public final class VonageSendReactionUseCase: SendReactionUseCase {

    private let plugin: VonageReactionsPlugin

    /// Creates a send reaction use case.
    /// - Parameter plugin: The reactions plugin to use for sending.
    public init(plugin: VonageReactionsPlugin) {
        self.plugin = plugin
    }

    /// Sends the emoji reaction.
    /// - Parameter emoji: The emoji item selected by the user.
    public func callAsFunction(_ emoji: String) throws {
        try plugin.sendReaction(emoji)
    }
}
