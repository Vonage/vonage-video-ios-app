//
//  Created by Vonage on 21/02/26.
//

import SwiftUI
import VERACommonUI

/// Closure invoked when the button is tapped.
///
/// Used by ``SettingsMeetingRoomButton`` to notify the parent that
/// the user wants to open settings.
public typealias OnClick = () -> Void

/// Gear button rendered in the meeting room bottom bar.
///
/// Uses ``OngoingActivityControlImageButton`` for consistent styling with other
/// meeting-room controls. Tapping fires the `onShowSettings` closure; the
/// sheet presentation is managed externally (in `VERAApp`) so it works both
/// when the button is rendered directly and from the overflow `Menu`.
///
/// Unlike ``SettingsWaitingRoomButton``, this button does not manage the sheet presentation
/// itself. The caller is responsible for presenting the settings view when the closure is invoked.
public struct SettingsMeetingRoomButton: View {
    
    /// Closure invoked when the gear button is tapped.
    /// The caller should present the settings view in response.
    private let onShowSettings: OnClick?

    /// Creates a new meeting room settings button.
    ///
    /// - Parameter onShowSettings: Optional closure called when the button is tapped.
    ///                             Typically provided by the parent view to handle sheet presentation.
    public init(onShowSettings: OnClick? = nil) {
        self.onShowSettings = onShowSettings
    }

    public var body: some View {
        OngoingActivityControlImageButton(
            isActive: false,
            image: Image(systemName: "gearshape.fill"),
            action: {
                onShowSettings?()
            }
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    SettingsMeetingRoomButton {
        print("Settings tapped")
    }
    .padding()
    .preferredColorScheme(.dark)
}
#endif
