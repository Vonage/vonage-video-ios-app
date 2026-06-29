//
//  Created by Vonage on 19/06/2026.
//

import SwiftUI

/// A component view that wraps `EmojiHorizontalPickerView` with a view model.
///
/// `EmojiHorizontalPickerViewContainer` connects the horizontal picker UI to
/// `EmojiPickerContainerViewModel`. The view model provides the picker
/// configuration, exposes the sending state, and handles selected emojis by
/// sending reactions through the use case layer.
///
/// ## Usage
/// ```swift
/// let viewModel = EmojiPickerContainerViewModel(
///     sendReactionUseCase: sendReactionUseCase
/// )
///
/// EmojiHorizontalPickerViewContainer(viewModel: viewModel)
/// ```
public struct EmojiHorizontalPickerViewContainer: View {
    @Environment(\.meetingRoomTheme) private var theme

    // MARK: - Properties

    @ObservedObject private var viewModel: EmojiPickerContainerViewModel

    private var emojis: [UIEmojiReaction] {
        viewModel.configuration.emojis
    }

    private var showsHighlight: Bool {
        viewModel.configuration.showsHighlight
    }

    private var highlightDuration: Double {
        viewModel.configuration.highlightDuration
    }

    // MARK: - Initialization

    /// Creates a horizontal emoji picker component view.
    /// - Parameters:
    ///   - viewModel: The view model that provides picker configuration,
    ///     sending state, and the action used when an emoji is selected.
    public init(viewModel: EmojiPickerContainerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        EmojiHorizontalPickerView(
            emojis: emojis,
            showsHighlight: showsHighlight,
            highlightDuration: highlightDuration,
            highlightColor: theme.secondary
        ) { emoji in
            select(emoji)
        }
        .disabled(viewModel.isSending)
    }

    func select(_ emoji: UIEmojiReaction) {
        viewModel.sendReaction(emoji)
    }
}

#if DEBUG
    #Preview("Container - Default") {
        EmojiHorizontalPickerViewContainer(
            viewModel: EmojiPickerContainerViewModel(
                sendReactionUseCase: PreviewSendReactionUseCase()
            )
        )
        .padding()
        .background(Color.gray.opacity(0.12))
    }

    #Preview("Container - Few Emojis") {
        EmojiHorizontalPickerViewContainer(
            viewModel: EmojiPickerContainerViewModel(
                configuration: EmojiPickerConfiguration(
                    emojis: Array(UIEmojiReaction.defaultEmojis.prefix(3))
                ),
                sendReactionUseCase: PreviewSendReactionUseCase()
            )
        )
        .padding()
        .background(Color.gray.opacity(0.12))
    }

    #Preview("Container - Dark") {
        EmojiHorizontalPickerViewContainer(
            viewModel: EmojiPickerContainerViewModel(
                sendReactionUseCase: PreviewSendReactionUseCase()
            )
        )
        .padding()
        .background(Color.gray.opacity(0.12))
        .preferredColorScheme(.dark)
    }

    #Preview("Container - Custom Highlight") {
        EmojiHorizontalPickerViewContainer(
            viewModel: EmojiPickerContainerViewModel(
                sendReactionUseCase: PreviewSendReactionUseCase()
            )
        )
        .padding()
        .background(Color.gray.opacity(0.12))
    }

    private struct PreviewSendReactionUseCase: SendReactionUseCase {
        func callAsFunction(_ emoji: String) throws {}
    }
#endif
