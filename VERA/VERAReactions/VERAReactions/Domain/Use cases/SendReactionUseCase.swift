//
//  Created by Vonage on 10/2/26.
//

import Foundation

/// Use case protocol for sending emoji reactions.
///
/// Implementations handle the actual transport mechanism
/// (e.g., Vonage signals, WebSocket, etc.).
///
/// ## Usage
/// ```swift
/// let sendReaction: SendReactionUseCase = ...
///
/// EmojiPickerView(emojis: UIEmojiReaction.defaultEmojis) { emoji in
///     try? sendReaction(emoji)
/// }
/// ```
public protocol SendReactionUseCase {
    /// Sends an emoji reaction to all call participants.
    /// - Parameter emoji: The emoji to send.
    /// - Throws: An error if the reaction cannot be sent.
    func callAsFunction(_ emoji: String) throws
}
