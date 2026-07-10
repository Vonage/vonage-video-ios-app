//
//  Created by Vonage on 22/2/26.
//

import SwiftUI
import VERACommonUI

/// General section content: reset-to-defaults action.
///
/// Returns `Section` blocks intended to be embedded inside a parent `Form`.
struct GeneralSectionView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var statsOverlayEnabled: Bool
    private let isInActiveCall: Bool
    private let isCompactLayout: Bool

    init(
        viewModel: SettingsViewModel,
        isInActiveCall: Bool = false,
        statsOverlayEnabled: Binding<Bool> = .constant(false),
        isCompactLayout: Bool = false
    ) {
        self.viewModel = viewModel
        self._statsOverlayEnabled = statsOverlayEnabled
        self.isInActiveCall = isInActiveCall
        self.isCompactLayout = isCompactLayout
    }

    var body: some View {
        if isCompactLayout {
            compactBody
        } else {
            regularBody
        }
    }

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Show Overlay Stats".localized, isOn: $statsOverlayEnabled)
                .accessibilityIdentifier(SettingsAccessibilityID.overlayStatsToggle)
            if !isInActiveCall {
                SettingsDivider()
                content
            }
        }
    }

    private var regularBody: some View {
        Section {
            Toggle("Show Overlay Stats".localized, isOn: $statsOverlayEnabled)
                .accessibilityIdentifier(SettingsAccessibilityID.overlayStatsToggle)
            if !isInActiveCall {
                content
            }
        } header: {
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                if isInActiveCall {
                    ActiveCallWarningText()
                } else {
                    Text("Restores all settings to their default values.".localized)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isInActiveCall {
            HStack {
                Text("Reset to Defaults".localized)
                Spacer()
                Text("Off limits".localized)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.secondary)
        } else {
            Button {
                Task { @MainActor in
                    await viewModel.resetToDefaults()
                }
            } label: {
                Text("Reset to Defaults".localized)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .background(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHint("Restores every setting to its default value.".localized)
            .accessibilityIdentifier(SettingsAccessibilityID.resetDefaultsButton)
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview {
        Form {
            GeneralSectionView(viewModel: .preview, isCompactLayout: true)
        }
        .preferredColorScheme(.dark)
    }

    #Preview("General Section - Active Call") {
        Form {
            GeneralSectionView(viewModel: .preview, isInActiveCall: true, isCompactLayout: true)
        }
        .preferredColorScheme(.dark)
    }
#endif
