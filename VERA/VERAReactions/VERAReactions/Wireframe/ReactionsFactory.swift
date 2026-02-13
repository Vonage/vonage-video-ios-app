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

    /// Creates an emoji button container view using an existing view model.
    ///
    /// Use this method when the view model is managed externally (e.g., stored
    /// in a coordinator) to avoid retain cycles and control the lifecycle.
    ///
    /// - Parameter viewModel: The existing view model to use.
    /// - Returns: A configured EmojiButtonContainer view.
    public func makeEmojiButtonContainer(
        viewModel: EmojiButtonContainerViewModel
    ) -> EmojiButtonContainer {
        return EmojiButtonContainer(viewModel: viewModel)
    }

    /// Creates an emoji picker component with its view model.
    ///
    /// Use this method when you need access to the view model for testing
    /// or additional control over the picker behavior.
    ///
    /// - Returns: A tuple containing the configured view and its view model.
    public func makeEmojiPickerContainer() -> (view: EmojiPickerViewContainer, viewModel: EmojiPickerContainerViewModel)
    {
        let viewModel = EmojiPickerContainerViewModel(
            sendReactionUseCase: sendReactionUseCase
        )
        let view = EmojiPickerViewContainer(viewModel: viewModel)
        return (view, viewModel)
    }

    /// Creates an emoji button with its container view model.
    ///
    /// The button shows a popover with the emoji picker when tapped.
    /// Selecting an emoji sends the reaction and dismisses the picker.
    ///
    /// - Parameter configuration: The configuration for the emoji picker. Defaults to `.default`.
    /// - Returns: A tuple containing the configured container view and its view model.
    public func makeEmojiButton(
        configuration: EmojiPickerConfiguration = .default
    ) -> (view: EmojiButtonContainer, viewModel: EmojiButtonContainerViewModel) {
        let viewModel = EmojiButtonContainerViewModel(
            sendReactionUseCase: sendReactionUseCase,
            configuration: configuration
        )
        let view = EmojiButtonContainer(viewModel: viewModel)
        return (view, viewModel)
    }

    /// Returns the reactions repository for UI to observe incoming reactions.
    public var repository: any ReactionsRepository {
        reactionsRepository
    }
}
