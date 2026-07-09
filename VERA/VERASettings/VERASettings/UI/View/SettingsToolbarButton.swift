//
//  Created by Vonage on 08/07/26.
//

import SwiftUI
import VERACommonUI

/// Icon-only settings button for display in the navigation toolbar.
///
/// Unlike ``SettingsWaitingRoomButton`` (a circular icon button with background),
/// this button renders only the `gearshape.fill` SF Symbol with no circular
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

    /// Accessibility identifier for the settings toolbar button.
    public static let accessibilityID = "WaitingRoom.SettingsButton"

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
        .accessibilityIdentifier(Self.accessibilityID)
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

    #Preview("Comparison") {
        VStack(spacing: 40) {
            VStack(spacing: 8) {
                SettingsToolbarButton {
                    SettingsView(viewModel: .preview)
                }
                Text("Toolbar Style")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                SettingsWaitingRoomButton {
                    SettingsView(viewModel: .preview)
                }
                Text("Circular Style")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray)
    }
#endif
