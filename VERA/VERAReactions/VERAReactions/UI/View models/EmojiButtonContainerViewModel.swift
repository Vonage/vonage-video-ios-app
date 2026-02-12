//
//  Created by Vonage on 11/2/26.
//

import Combine
import Foundation

/// ViewModel for managing the emoji button and picker visibility state.
///
/// This ViewModel controls whether the emoji picker popover is shown
/// and coordinates with the `EmojiPickerComponentViewModel` for sending reactions.
public final class EmojiButtonContainerViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Whether the emoji picker popover is currently visible.
    @Published public var isPickerVisible: Bool = false

    /// The current state of the emoji button.
    public var state: EmojiButtonState {
        isPickerVisible ? .pickerVisible : .idle
    }

    // MARK: - Dependencies

    /// The use case for sending reactions.
    private let sendReactionUseCase: SendReactionUseCase

    /// The configuration for the emoji picker.
    private let configuration: EmojiPickerConfiguration

    // MARK: - Child ViewModel

    /// The ViewModel for the emoji picker component.
    /// Created lazily when the picker is shown.
    public lazy var pickerViewModel: EmojiPickerContainerViewModel = {
        EmojiPickerContainerViewModel(
            configuration: configuration,
            sendReactionUseCase: sendReactionUseCase
        )
    }()

    // MARK: - Initialization

    /// Creates an emoji button container ViewModel.
    /// - Parameters:
    ///   - sendReactionUseCase: The use case for sending reactions.
    ///   - configuration: The configuration for the emoji picker. Defaults to `.default`.
    public init(
        sendReactionUseCase: SendReactionUseCase,
        configuration: EmojiPickerConfiguration = .default
    ) {
        self.sendReactionUseCase = sendReactionUseCase
        self.configuration = configuration
    }

    // MARK: - Actions

    /// Toggles the visibility of the emoji picker.
    public func togglePicker() {
        pickerViewModel.isVisible.toggle()
        isPickerVisible.toggle()
    }

    /// Shows the emoji picker.
    public func showPicker() {
        isPickerVisible = true
        pickerViewModel.isVisible = true
    }

    /// Hides the emoji picker.
    public func hidePicker() {
        pickerViewModel.isVisible = false
        isPickerVisible = false
    }
}
