//
//  Created by Vonage on 11/2/26.
//

import SwiftUI

/// A component view that wraps `EmojiPickerView` with a ViewModel.
///
/// Connects the emoji picker UI to the `EmojiPickerComponentViewModel`,
/// which handles sending reactions through the use case layer.
///
/// ## Usage
/// ```swift
/// let viewModel = EmojiPickerComponentViewModel(
///     sendReactionUseCase: sendReactionUseCase
/// )
///
/// EmojiPickerViewContainer(viewModel: viewModel)
/// ```
public struct EmojiPickerViewContainer: View {

    // MARK: - Properties

    @ObservedObject private var viewModel: EmojiPickerContainerViewModel

    // MARK: - Initialization

    /// Creates an emoji picker component view.
    /// - Parameters:
    ///   - viewModel: The view model managing emoji selection and sending.
    public init(viewModel: EmojiPickerContainerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        EmojiPickerViewFactory.make(configuration: viewModel.configuration) { emoji in
            viewModel.sendReaction(emoji)
        }
        .disabled(viewModel.isSending)
    }
}

// MARK: - Preview

#if DEBUG
    struct EmojiPickerComponentView_Previews: PreviewProvider {
        static var previews: some View {
            EmojiPickerViewContainer(
                viewModel: EmojiPickerContainerViewModel(
                    sendReactionUseCase: PreviewSendReactionUseCase())
            ).padding()
        }
    }

    private struct PreviewSendReactionUseCase: SendReactionUseCase {
        func callAsFunction(_ emoji: String) throws {
            print("Preview: Sending reaction \(emoji)")
        }
    }
#endif
