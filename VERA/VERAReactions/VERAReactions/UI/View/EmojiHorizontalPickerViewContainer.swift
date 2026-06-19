//
//  Created by Vonage on 19/06/2026.
//

import SwiftUI

/// A component view that wraps `EmojiHorizontalPickerView` with a ViewModel.
public struct EmojiHorizontalPickerViewContainer: View {

    // MARK: - Properties

    @ObservedObject private var viewModel: EmojiPickerContainerViewModel

    // MARK: - Initialization

    /// Creates a horizontal emoji picker component view.
    /// - Parameter viewModel: The view model managing emoji selection and sending.
    public init(viewModel: EmojiPickerContainerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        EmojiHorizontalPickerView(
            emojis: viewModel.configuration.emojis,
            showsHighlight: viewModel.configuration.showsHighlight,
            highlightDuration: viewModel.configuration.highlightDuration
        ) { emoji in
            viewModel.sendReaction(emoji)
        }
        .disabled(viewModel.isSending)
    }
}

#if DEBUG
    #Preview {
        EmojiHorizontalPickerViewContainer(
            viewModel: EmojiPickerContainerViewModel(
                sendReactionUseCase: PreviewSendReactionUseCase())
        )
        .padding()
    }

    private struct PreviewSendReactionUseCase: SendReactionUseCase {
        func callAsFunction(_ emoji: String) throws {
            print("Preview: Sending reaction \(emoji)")
        }
    }
#endif
