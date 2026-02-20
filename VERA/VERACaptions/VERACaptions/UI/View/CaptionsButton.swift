//
//  Created by Vonage on 6/2/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// A toggle button that enables or disables live captions.
///
/// `CaptionsButton` is a **presentational** view that wraps
/// `OngoingActivityControlImageButton` from VERACommonUI. It displays:
/// - The **"CC off"** icon when captions are currently **enabled** (tap to disable).
/// - The **"CC on"** icon when captions are currently **disabled** (tap to enable).
///
/// > Note: The icon represents the *action* the tap will perform, not the
/// > current state.
///
/// ## Usage
///
/// Typically used through ``CaptionsButtonContainer``, which binds the
/// button to a ``CaptionsButtonViewModel``.
///
/// ```swift
/// CaptionsButton(state: .disabled) {
///     // handle tap
/// }
/// ```
///
/// - SeeAlso: ``CaptionsButtonContainer``, ``CaptionsButtonViewModel``
struct CaptionsButton: View {
    /// The current captions activation state (`.enabled` or `.disabled`).
    private let state: CaptionsState
    /// Closure invoked when the user taps the button.
    private let action: () -> Void

    /// Creates a captions toggle button.
    ///
    /// - Parameters:
    ///   - state: The current ``CaptionsState``.
    ///   - action: The closure to execute on tap. Defaults to a no-op.
    init(
        state: CaptionsState,
        action: @escaping () -> Void = {}
    ) {
        self.state = state
        self.action = action
    }

    var body: some View {
        OngoingActivityControlImageButton(
            isActive: state.captionsEnabled,
            image: state.captionsEnabled
                ? VERACommonUIAsset.Images.closedCaptioningOffSolid.swiftUIImage
                : VERACommonUIAsset.Images.closedCaptioningSolid.swiftUIImage,
            action: action)
    }
}

#Preview {
    VStack(spacing: 20) {
        CaptionsButton(state: .enabled(""))
        CaptionsButton(state: .disabled)
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        CaptionsButton(state: .enabled(""))
        CaptionsButton(state: .disabled)
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
