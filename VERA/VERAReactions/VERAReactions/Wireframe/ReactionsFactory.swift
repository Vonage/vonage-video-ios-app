//
//  Created by Vonage on 11/2/26.
//

import SwiftUI

/// Factory for creating reaction-related views.
///
/// Provides configured instances of emoji picker and reactions overlay views
/// with the necessary dependencies injected.
public final class ReactionsFactory {

    private let reactionsRepository: any ReactionsRepository
    private let sendReactionUseCase: SendReactionUseCase

    /// Creates a new reactions factory.
    /// - Parameters:
    ///   - reactionsRepository: Repository for observing incoming reactions.
    ///   - sendReactionUseCase: Use case for sending reactions.
    public init(
        reactionsRepository: any ReactionsRepository,
        sendReactionUseCase: SendReactionUseCase
    ) {
        self.reactionsRepository = reactionsRepository
        self.sendReactionUseCase = sendReactionUseCase
    }

    /// Creates an emoji picker component with its view model.
    ///
    /// Use this method when you need access to the view model for testing
    /// or additional control over the picker behavior.
    ///
    /// - Parameter onDismiss: Optional callback when picker should be dismissed.
    /// - Returns: A tuple containing the configured view and its view model.
    public func makeEmojiPickerComponent(
        onDismiss: (() -> Void)? = nil
    ) -> (view: EmojiPickerComponentView, viewModel: EmojiPickerComponentViewModel) {
        let viewModel = EmojiPickerComponentViewModel(
            sendReactionUseCase: sendReactionUseCase,
            onDismiss: onDismiss
        )
        let view = EmojiPickerComponentView(viewModel: viewModel)
        return (view, viewModel)
    }

    /// Returns the reactions repository for UI to observe incoming reactions.
    public var repository: any ReactionsRepository {
        reactionsRepository
    }
}
