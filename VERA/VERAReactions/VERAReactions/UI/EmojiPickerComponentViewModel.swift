//
//  EmojiPickerComponentViewModel.swift
//  VERAReactions
//

import Combine
import Foundation

/// ViewModel for the emoji picker component.
///
/// Manages emoji selection and delegates sending reactions through the use case.
/// Follows the MVVM pattern used across the VERA app.
///
/// ## Usage
/// ```swift
/// let viewModel = EmojiPickerComponentViewModel(
///     sendReactionUseCase: sendReactionUseCase,
///     onDismiss: { print("Picker dismissed") }
/// )
///
/// EmojiPickerComponentView(viewModel: viewModel)
/// ```
public final class EmojiPickerComponentViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The list of emojis available for selection.
    @Published public private(set) var emojis: [UIEmojiReaction]

    /// Indicates if a reaction is currently being sent.
    @Published public private(set) var isSending: Bool = false

    /// The last error that occurred when sending a reaction, if any.
    @Published public private(set) var lastError: Error?

    // MARK: - Dependencies

    private let sendReactionUseCase: SendReactionUseCase
    private let onDismiss: (() -> Void)?

    // MARK: - Initialization

    /// Creates a new emoji picker component view model.
    /// - Parameters:
    ///   - emojis: The list of emojis to display. Defaults to `UIEmojiReaction.defaultEmojis`.
    ///   - sendReactionUseCase: The use case for sending reactions.
    ///   - onDismiss: Optional callback invoked after a reaction is sent.
    public init(
        emojis: [UIEmojiReaction] = UIEmojiReaction.defaultEmojis,
        sendReactionUseCase: SendReactionUseCase,
        onDismiss: (() -> Void)? = nil
    ) {
        self.emojis = emojis
        self.sendReactionUseCase = sendReactionUseCase
        self.onDismiss = onDismiss
    }

    // MARK: - Public Methods

    /// Sends the selected emoji reaction.
    ///
    /// Invokes the `SendReactionUseCase` with the emoji string and
    /// calls `onDismiss` after successful sending.
    ///
    /// - Parameter emoji: The emoji reaction to send.
    public func sendReaction(_ emoji: UIEmojiReaction) {
        isSending = true
        lastError = nil

        do {
            try sendReactionUseCase(emoji.emoji)
            onDismiss?()
        } catch {
            lastError = error
        }

        isSending = false
    }

    /// Dismisses the picker without sending a reaction.
    public func dismiss() {
        onDismiss?()
    }
}
