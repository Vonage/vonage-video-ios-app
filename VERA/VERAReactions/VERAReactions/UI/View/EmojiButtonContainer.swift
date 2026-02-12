//
//  Created by Vonage on 11/2/26.
//

import SwiftUI

/// Constants for EmojiButtonContainer layout and animation
private enum EmojiButtonContainerConstants {
    /// Padding between picker and button
    static let pickerBottomPadding: CGFloat = 16

    /// Vertical offset to position picker above button
    static let pickerVerticalOffset: CGFloat = -44

    /// Scale factor for picker appear/disappear animation
    static let animationScale: CGFloat = 0.95

    /// Duration of appear/disappear animation
    static let animationDuration: Double = 0.2
}

/// A container view that wraps the emoji button with a popover for the emoji picker.
///
/// This is the public-facing view to be used in the meeting room toolbar.
/// When the button is tapped, it shows a popover with the `EmojiButtonContainer`.
public struct EmojiButtonContainer: View {

    // MARK: - Properties

    /// The ViewModel managing the button and picker state.
    @ObservedObject private var viewModel: EmojiButtonContainerViewModel

    // MARK: - Initialization

    /// Creates an emoji button container.
    /// - Parameter viewModel: The ViewModel for managing state.
    public init(viewModel: EmojiButtonContainerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        EmojiButton(
            state: viewModel.state,
            action: viewModel.togglePicker
        )
        .overlay(alignment: .bottom) {
            if viewModel.pickerViewModel.isVisible {
                pickerContent
            }
        }
        .animation(
            .easeInOut(duration: EmojiButtonContainerConstants.animationDuration),
            value: viewModel.pickerViewModel.isVisible)
    }

    // MARK: - Private Views

    @ViewBuilder
    private var pickerContent: some View {
        EmojiPickerViewContainer(viewModel: viewModel.pickerViewModel)
            .padding(.bottom, EmojiButtonContainerConstants.pickerBottomPadding)
            .offset(y: EmojiButtonContainerConstants.pickerVerticalOffset)
            .transition(
                .opacity.combined(with: .scale(scale: EmojiButtonContainerConstants.animationScale, anchor: .bottom)))
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        EmojiButtonContainer(
            viewModel: EmojiButtonContainerViewModel(
                sendReactionUseCase: PreviewSendReactionUseCase()
            )
        )
        .padding()
        .background(.white)
    }

    /// A mock use case for previews.
    private struct PreviewSendReactionUseCase: SendReactionUseCase {
        func callAsFunction(_ emoji: String) throws {
            print("Preview: Sending reaction \(emoji)")
        }
    }
#endif
