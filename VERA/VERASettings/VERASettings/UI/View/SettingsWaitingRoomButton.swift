//
//  Created by Vonage on 21/02/26.
//

import SwiftUI
import VERACommonUI

/// Closure that creates and returns a configured ``SettingsView``.
///
/// Used by ``SettingsWaitingRoomButton`` to lazily instantiate the settings view
/// when the user taps the gear button.
public typealias OnLaunchView = () -> SettingsView

/// Circular gear button shown in the waiting room's trailing button row.
///
/// Tapping opens the ``SettingsView`` in a sheet modal presentation.
/// Uses ``CircularControlImageButton`` from VERACommonUI for consistent styling.
///
/// The button creates the settings view lazily via the `makeSettingsView` closure,
/// ensuring resources are allocated only when needed.
public struct SettingsWaitingRoomButton: View {

    /// Closure for creating the settings view when the button is tapped.
    /// If `nil`, the button will show the sheet but with no content.
    private let makeSettingsView: OnLaunchView?
    
    /// Controls the presentation state of the settings sheet.
    @State private var showSettings = false

    /// Creates a new waiting room settings button.
    ///
    /// - Parameter makeSettingsView: Optional closure that creates the settings view.
    ///                               Typically provided by ``SettingsFactory``.
    public init(makeSettingsView: OnLaunchView? = nil) {
        self.makeSettingsView = makeSettingsView
    }

    public var body: some View {
        CircularControlImageButton(
            isActive: true,
            image: Image(systemName: "gearshape.fill"),
            action: { showSettings = true }
        )
        .sheet(isPresented: $showSettings) {
            makeSettingsView?()
                .presentationDetents([.large])
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    SettingsWaitingRoomButton {
        SettingsView(viewModel: .preview)
    }
}
#endif
