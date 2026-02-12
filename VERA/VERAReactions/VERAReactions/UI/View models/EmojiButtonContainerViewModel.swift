//
//  Created by Vonage on 11/2/26.
//

import Combine
import Foundation

/// ViewModel for managing the emoji button and picker visibility state.
///
/// This ViewModel controls whether the emoji picker popover is shown
/// and coordinates with the `EmojiPickerContainerViewModel` for sending reactions.
/// Uses a single source of truth for visibility via `pickerViewModel.isVisible`.
public final class EmojiButtonContainerViewModel: ObservableObject {

    // MARK: - Computed Properties

    /// Whether the emoji picker popover is currently visible.
    /// Derived from the picker ViewModel's visibility state.
    public var isPickerVisible: Bool {
        pickerViewModel.isVisible
    }

    /// The current state of the emoji button.
    public var state: EmojiButtonState {
        pickerViewModel.isVisible ? .pickerVisible : .idle
    }

    // MARK: - Dependencies

    /// The use case for sending reactions.
    private let sendReactionUseCase: SendReactionUseCase

    /// The configuration for the emoji picker.
    private let configuration: EmojiPickerConfiguration

    /// Subscriptions for forwarding objectWillChange from child ViewModel.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Child ViewModel

    /// The ViewModel for the emoji picker component.
    /// Created lazily when the picker is shown.
    public lazy var pickerViewModel: EmojiPickerContainerViewModel = {
        let viewModel = EmojiPickerContainerViewModel(
            configuration: configuration,
            sendReactionUseCase: sendReactionUseCase
        )
        // Forward child's objectWillChange to parent so SwiftUI updates when picker visibility changes
        viewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        return viewModel
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
    }

    /// Shows the emoji picker.
    public func showPicker() {
        pickerViewModel.isVisible = true
    }

    /// Hides the emoji picker.
    public func hidePicker() {
        pickerViewModel.isVisible = false
    }
}
