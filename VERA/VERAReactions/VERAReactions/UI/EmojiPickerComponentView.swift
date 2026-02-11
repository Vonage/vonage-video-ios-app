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
///     sendReactionUseCase: sendReactionUseCase,
///     onDismiss: { /* dismiss picker */ }
/// )
///
/// EmojiPickerComponentView(viewModel: viewModel)
/// ```
public struct EmojiPickerComponentView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var viewModel: EmojiPickerComponentViewModel
    
    // MARK: - Initialization
    
    /// Creates an emoji picker component view.
    /// - Parameters:
    ///   - viewModel: The view model managing emoji selection and sending.
    public init(viewModel: EmojiPickerComponentViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        EmojiPickerViewFactory.make(configuration: viewModel.configuration) { emoji in
            viewModel.sendReaction(emoji)
        }
        .disabled(viewModel.isSending)
        .opacity(viewModel.isSending ? 0.6 : 1.0)
    }
}

// MARK: - Preview

#if DEBUG
struct EmojiPickerComponentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPickerComponentView(
            viewModel: EmojiPickerComponentViewModel(
                sendReactionUseCase: PreviewSendReactionUseCase()
            )
        )
        .padding()
    }
}

private struct PreviewSendReactionUseCase: SendReactionUseCase {
    func callAsFunction(_ emoji: String) throws {
        print("Preview: Sending reaction \(emoji)")
    }
}
#endif
