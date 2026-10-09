//
//  Created by Vonage.
//

import SwiftUI
import VERADomain

/// Independent publishing settings for the ReplayKit broadcast extension.
struct ScreenSharingSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    var isCompactLayout = false

    var body: some View {
        if isCompactLayout {
            controls
        } else {
            Section { controls }
        }
    }

    private var preferences: Binding<PublisherSettingsPreferences> { $viewModel.settingsPreference }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Applies when the next screen share starts.".localized)
                .font(.caption).foregroundStyle(.secondary)
            Picker("Optimize for".localized, selection: preferences.screenShareContentHint) {
                ForEach(VideoContentHint.allCases, id: \.self) { hint in
                    Text(hint.displayName).tag(hint)
                }
            }
            .accessibilityIdentifier(SettingsAccessibilityID.screenShareContentHintPicker)
            SettingsDivider()
            Picker("Codec".localized, selection: preferences.screenShareCodecMode) {
                ForEach(SettingsScreenShareCodecMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .accessibilityIdentifier(SettingsAccessibilityID.screenShareCodecPicker)
            if viewModel.settingsPreference.screenShareCodecMode == .manual {
                Text("Codec priority".localized).font(.headline)
                ManualCodecReorderView(
                    orderedCodecs: viewModel.settingsPreference.screenShareCodecPreference.orderedCodecs,
                    priorityLabel: { codec in
                        guard
                            let index = viewModel.settingsPreference.screenShareCodecPreference.orderedCodecs
                                .firstIndex(of: codec)
                        else { return "" }
                        return String(index + 1)
                    },
                    onMove: { source, destination in
                        viewModel.settingsPreference.screenShareCodecPreference.orderedCodecs.move(
                            fromOffsets: source, toOffset: destination)
                    })
            }
            Text(
                "Choose a codec order for shared content, or follow the camera. Applies the next time you start sharing."
                    .localized
            )
            .font(.caption).foregroundStyle(.secondary)
            SettingsDivider()
            Picker("Frame rate".localized, selection: preferences.screenShareFrameRate) {
                Text("SDK default".localized).tag(Optional<SettingsVideoFrameRate>.none)
                ForEach(SettingsVideoFrameRate.allCases.reversed()) { rate in
                    Text(rate.displayName).tag(Optional(rate))
                }
            }
            .accessibilityIdentifier(SettingsAccessibilityID.screenShareFrameRatePicker)
            SettingsDivider()
            Picker("Resolution".localized, selection: preferences.screenShareResolution) {
                Text("SDK default".localized).tag(Optional<SettingsScreenShareResolution>.none)
                ForEach(SettingsScreenShareResolution.allCases) { resolution in
                    Text(resolution.rawValue).tag(Optional(resolution))
                }
            }
            .accessibilityIdentifier(SettingsAccessibilityID.screenShareResolutionPicker)
            Text("Maximum output size; the screen aspect ratio is preserved.".localized)
                .font(.caption).foregroundStyle(.secondary)
            SettingsDivider()
            Picker("Bitrate".localized, selection: preferences.screenShareBitratePreset) {
                Text("SDK default".localized).tag(Optional<SettingsVideoBitratePreset>.none)
                ForEach(SettingsVideoBitratePreset.allCases.filter { $0 != .default }) { preset in
                    Text(preset.displayName).tag(Optional(preset))
                }
            }
            .accessibilityIdentifier(SettingsAccessibilityID.screenShareBitratePicker)
            if viewModel.settingsPreference.screenShareBitratePreset == .custom {
                Text("Custom bitrate".localized).font(.headline)
                Text("\(viewModel.settingsPreference.screenShareMaxVideoBitrate / 1000) kbps")
                Slider(
                    value: Binding(
                        get: { Double(viewModel.settingsPreference.screenShareMaxVideoBitrate) },
                        set: { viewModel.settingsPreference.screenShareMaxVideoBitrate = Int32($0) }),
                    in: 5_000...10_000_000, step: 5_000
                )
                .accessibilityIdentifier(SettingsAccessibilityID.screenShareCustomBitrateSlider)
                HStack {
                    Text("5 kbps".localized)
                    Spacer()
                    Text("10 Mbps".localized)
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            SettingsDivider()
            Toggle("Scalable screen sharing".localized, isOn: preferences.scalableScreenshareEnabled)
                .accessibilityIdentifier(SettingsAccessibilityID.scalableScreenShareToggle)
            Text(
                "Sends multiple quality layers so each viewer gets the best their connection allows. Applies the next time you start sharing."
                    .localized
            )
            .font(.caption).foregroundStyle(.secondary)
        }
    }
}
