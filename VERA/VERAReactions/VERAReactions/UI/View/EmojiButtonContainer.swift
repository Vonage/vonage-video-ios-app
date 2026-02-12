//
//  Created by Vonage on 11/2/26.
//

import SwiftUI

/// A container view that wraps the emoji button with a popover for the emoji picker.
///
/// This is the public-facing view to be used in the meeting room toolbar.
/// When the button is tapped, it shows a popover with the `EmojiPickerComponentView`.
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
        .popover(isPresented: $viewModel.isPickerVisible) {
            pickerContent
        }
        .onChange(of: viewModel.isPickerVisible) { isVisible in
            if !isVisible {
                viewModel.hidePicker()
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var pickerContent: some View {
        if #available(iOS 16.4, *) {
            EmojiPickerViewContainer(viewModel: viewModel.pickerViewModel)
                .presentationCompactAdaptation(.popover)
        } else {
            EmojiPickerViewContainer(viewModel: viewModel.pickerViewModel)
        }
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
