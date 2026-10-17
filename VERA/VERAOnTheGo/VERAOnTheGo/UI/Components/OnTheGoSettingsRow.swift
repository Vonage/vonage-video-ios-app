//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import VERACommonUI

#if canImport(UIKit)
    import UIKit
#endif

/// The user-preference row for On-the-Go mode, designed to be embedded inside
/// a `Form` by the host settings screen.
///
/// Contains a toggle bound to ``OnTheGoPreferencesRepository/suggestWhenMoving``
/// plus an explanatory footer, and a warning with an "Open iOS Settings" button
/// when motion & fitness access is denied.
public struct OnTheGoSettingsRow: View {

    private static let footerText =
        "When you're walking, cycling or driving during a call, we'll offer a simpler audio-first screen."
        + " You can always switch manually from the more menu."

    @Environment(\.meetingRoomTheme) private var theme

    private let preferences: OnTheGoPreferencesRepository
    private let isMotionPermissionDenied: Bool

    @State private var isOn: Bool

    public init(
        preferences: OnTheGoPreferencesRepository,
        isMotionPermissionDenied: Bool
    ) {
        self.preferences = preferences
        self.isMotionPermissionDenied = isMotionPermissionDenied
        self._isOn = State(initialValue: preferences.suggestWhenMoving)
    }

    public var body: some View {
        Section {
            Toggle(
                "Suggest On-the-Go mode when moving".localized,
                isOn: $isOn
            )
            .accessibilityIdentifier(OnTheGoAccessibilityID.suggestWhenMovingToggle)
            .onChange(of: isOn) { _, newValue in
                preferences.suggestWhenMoving = newValue
            }
            .onReceive(preferences.suggestWhenMovingPublisher) { isOn = $0 }

            if isMotionPermissionDenied {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(theme.warning)
                    Text("Motion & Fitness access is off.".localized)
                    #if canImport(UIKit)
                        Button("Open iOS Settings".localized) {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            UIApplication.shared.open(url)
                        }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier(OnTheGoAccessibilityID.openSettingsButton)
                    #endif
                }
                .font(.footnote)
                .foregroundStyle(theme.warning)
            }
        } footer: {
            Text(Self.footerText.localized)
        }
    }
}
