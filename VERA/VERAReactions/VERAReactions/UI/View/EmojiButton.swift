//
//  Created by Vonage on 11/2/26.
//

import SwiftUI
import VERACommonUI

/// Represents the state of the emoji button.
public enum EmojiButtonState: Equatable {
    /// The picker is hidden.
    case idle
    /// The picker is visible.
    case pickerVisible

    /// Whether the picker is currently visible.
    public var isPickerVisible: Bool {
        self == .pickerVisible
    }
}

/// Internal button view for toggling the emoji picker.
///
/// Uses `OngoingActivityControlImageButton` from VERACommonUI for consistent styling
/// with other meeting room toolbar buttons like Archive and Background Effects.
struct EmojiButton: View {

    // MARK: - Properties

    /// The current state of the emoji button.
    private let state: EmojiButtonState

    /// Action to perform when the button is tapped.
    private let action: () -> Void

    // MARK: - Initialization

    /// Creates an emoji button.
    /// - Parameters:
    ///   - state: The current state of the button.
    ///   - action: The action to perform when tapped.
    init(state: EmojiButtonState, action: @escaping () -> Void = {}) {
        self.state = state
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        OngoingActivityControlImageButton(
            isActive: state.isPickerVisible,
            image: VERACommonUIAsset.Images.emojiSolid.swiftUIImage,
            action: action
        )
        .accessibilityLabel(String(localized: "Reactions", bundle: .veraReactions))
        .accessibilityHint(
            state.isPickerVisible
                ? String(localized: "Close emoji picker", bundle: .veraReactions)
                : String(localized: "Open emoji picker", bundle: .veraReactions)
        )
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Default") {
        VStack(spacing: 20) {
            EmojiButton(state: .idle) {}
            EmojiButton(state: .pickerVisible) {}
        }
        .padding()
        .background(.white)
    }
#endif
