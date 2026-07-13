//
//  Created by Vonage on 08/07/26.
//

import SwiftUI
import VERACommonUI

/// Closure that creates and returns a configured ``SettingsView``
public typealias OnLaunchView = () -> SettingsView

/// Icon-only settings button for display in the navigation toolbar.
///
/// This button renders only the `gearshape.fill` SF Symbol with no circular
/// background, border, or fill color. Designed for use in SwiftUI's `.toolbar`
/// modifier where minimal, icon-only buttons are preferred.
///
/// Tapping opens the ``SettingsView`` in a sheet modal presentation.
/// The button creates the settings view lazily via the `makeSettingsView` closure,
/// ensuring resources are allocated only when needed.
///
/// ## Usage
/// ```swift
/// .toolbar {
///     ToolbarItem(placement: .primaryAction) {
///         SettingsToolbarButton {
///             settingsFactory.makeSettingsView()
///         }
///     }
/// }
/// ```
public struct SettingsToolbarButton: View {

    /// Closure for creating the settings view when the button is tapped.
    /// If `nil`, the button will show the sheet but with no content.
    private let makeSettingsView: OnLaunchView?

    /// Controls the presentation state of the settings sheet.
    @State private var showSettings = false

    /// Creates a new toolbar settings button.
    ///
    /// - Parameter makeSettingsView: Optional closure that creates the settings view.
    ///                               Typically provided by ``SettingsFactory``.
    public init(makeSettingsView: OnLaunchView? = nil) {
        self.makeSettingsView = makeSettingsView
    }

    public var body: some View {
        Button(action: { showSettings = true }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.primary)
        }
        .accessibilityIdentifier(SettingsAccessibilityID.waitingRoomSettingsButton)
        .sheet(isPresented: $showSettings) {
            makeSettingsView?()
                .presentationDetents([.large])
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview("Light") {
        ZStack {
            Color.gray.opacity(0.3)
            SettingsToolbarButton {
                SettingsView(viewModel: .preview)
            }
        }
        .frame(width: 80, height: 80)
    }

    #Preview("Dark") {
        ZStack {
            Color.gray.opacity(0.3)
            SettingsToolbarButton {
                SettingsView(viewModel: .preview)
            }
        }
        .frame(width: 80, height: 80)
        .preferredColorScheme(.dark)
    }
#endif
