//
//  Created by Vonage on 11/2/26.
//

import Combine
import Foundation

/// ViewModel for the emoji picker component.
///
/// Manages emoji selection and delegates sending reactions through the use case.
/// Controls visibility through the `isVisible` property which is set to `false`
/// after a reaction is sent. Follows the MVVM pattern used across the VERA app.
///
/// ## Usage
/// ```swift
/// let viewModel = EmojiPickerComponentViewModel(
///     sendReactionUseCase: sendReactionUseCase
/// )
///
/// EmojiPickerComponentView(viewModel: viewModel)
///     .popover(isPresented: $viewModel.isVisible) { ... }
/// ```
public final class EmojiPickerContainerViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Controls whether the picker is visible.
    @Published public var isVisible: Bool = false

    /// The picker configuration containing emojis and layout settings.
    @Published public private(set) var configuration: EmojiPickerConfiguration

    /// Indicates if a reaction is currently being sent.
    @Published public private(set) var isSending: Bool = false

    /// The last error that occurred when sending a reaction, if any.
    @Published public private(set) var lastError: Error?

    // MARK: - Dependencies

    private let sendReactionUseCase: SendReactionUseCase

    // MARK: - Initialization

    /// Creates a new emoji picker component view model.
    /// - Parameters:
    ///   - configuration: The picker configuration
    ///   - sendReactionUseCase: The use case for sending reactions.
    public init(
        configuration: EmojiPickerConfiguration = .default,
        sendReactionUseCase: SendReactionUseCase
    ) {
        self.configuration = configuration
        self.sendReactionUseCase = sendReactionUseCase
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
            isVisible = false
        } catch {
            lastError = error
        }

        isSending = false
    }

    /// Dismisses the picker without sending a reaction.
    public func dismiss() {
        isVisible = false
    }
}
