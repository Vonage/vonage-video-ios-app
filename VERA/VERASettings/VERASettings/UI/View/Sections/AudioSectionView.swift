//
//  Created by Vonage on 22/2/26.
//

import SwiftUI
import VERACommonUI

/// Audio section content: audio bitrate slider and fallback toggles.
///
/// Returns `Section` blocks intended to be embedded inside a parent `Form`.
struct AudioSectionView: View {

    @ObservedObject var viewModel: SettingsViewModel
    private let isInActiveCall: Bool
    private let isCompactLayout: Bool

    // Local Double mirror of the Int32 bitrate so Slider can bind to it.
    @State private var audioBitrateSlider = Double(AudioSettingsConstants.defaultAudioBitrate)

    init(
        viewModel: SettingsViewModel,
        isInActiveCall: Bool = false,
        isCompactLayout: Bool = false
    ) {
        self.viewModel = viewModel
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

    @ViewBuilder
    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            audioBitrateContent
            SettingsDivider()
            if isInActiveCall {
                ActiveCallWarningText()
            }
            opusDtxContent
            SettingsDivider()
            if isInActiveCall {
                ActiveCallWarningText()
            }
            publisherFallbackContent
            SettingsDivider()
            if isInActiveCall {
                ActiveCallWarningText()
            }
            subscriberFallbackContent
            if isInActiveCall {
                ActiveCallWarningText()
            }
        }
    }

    @ViewBuilder
    private var regularBody: some View {
        Section {
            audioBitrateContent
        } header: {
            Text("Audio Bitrate".localized)
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text(
                    "Controls the maximum audio encoding bitrate sent to the session. Higher values improve quality but use more bandwidth."
                        .localized)
                if isInActiveCall {
                    ActiveCallWarningText()
                }
            }
        }

        Section {
            opusDtxContent
        } header: {
            Text("Discontinuous Transmission".localized)
        } footer: {
            ActiveCallFooter(
                isInActiveCall: isInActiveCall,
                description:
                    "Enabling Opus DTX can reduce bandwidth usage in streams that have long periods of silence."
                    .localized)
        }

        Section {
            publisherFallbackContent
        } header: {
            Text("Publisher Fallback".localized)
        } footer: {
            ActiveCallFooter(
                isInActiveCall: isInActiveCall,
                description:
                    "When enabled, your video stops rendering on other devices during poor network conditions to preserve audio."
                    .localized)
        }

        Section {
            subscriberFallbackContent
        } header: {
            Text("Subscriber Fallback".localized)
        } footer: {
            ActiveCallFooter(
                isInActiveCall: isInActiveCall,
                description:
                    "When enabled, you receive audio only from other participants during poor network conditions."
                    .localized)
        }
    }

    @ViewBuilder
    private var audioBitrateContent: some View {
        if isInActiveCall {
            LockedValueSection(
                title: "Audio Bitrate".localized,
                value: viewModel.maxAudioBitrateFormatted
            )
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Audio Bitrate".localized, selection: $viewModel.audioBitrateMode) {
                    ForEach(SettingsAudioBitrateMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                if viewModel.audioBitrateMode == .custom {
                    Text("Max Audio Bitrate".localized(args: viewModel.maxAudioBitrateFormatted))
                        .font(.subheadline)

                    Slider(
                        value: $audioBitrateSlider,
                        in: AudioSettingsConstants.audioBitrateRange,
                        step: AudioSettingsConstants.audioBitrateStep
                    )
                    .onChange(of: audioBitrateSlider) { newValue in
                        viewModel.setMaxAudioBitrate(newValue)
                    }
                    .onAppear {
                        audioBitrateSlider = Double(
                            viewModel.maxAudioBitrate ?? AudioSettingsConstants.defaultAudioBitrate)
                    }
                    .onChange(of: viewModel.maxAudioBitrate) { newValue in
                        audioBitrateSlider = Double(newValue ?? AudioSettingsConstants.defaultAudioBitrate)
                    }

                    HStack {
                        Text("6 kbps".localized)
                        Spacer()
                        Text("510 kbps".localized)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var opusDtxContent: some View {
        if isInActiveCall {
            LockedToggleRow(
                title: "Enable Opus Dtx".localized,
                value: viewModel.settingsPreference.opusDtxEnabled
            )
        } else {
            Toggle("Enable Opus Dtx".localized, isOn: $viewModel.settingsPreference.opusDtxEnabled)
        }
    }

    @ViewBuilder
    private var publisherFallbackContent: some View {
        if isInActiveCall {
            LockedToggleRow(
                title: "Publisher Audio Fallback".localized,
                value: viewModel.settingsPreference.publisherAudioFallbackEnabled
            )
        } else {
            Toggle(
                "Publisher Audio Fallback".localized,
                isOn: $viewModel.settingsPreference.publisherAudioFallbackEnabled
            )
        }
    }

    @ViewBuilder
    private var subscriberFallbackContent: some View {
        if isInActiveCall {
            LockedToggleRow(
                title: "Subscriber Audio Fallback".localized,
                value: viewModel.settingsPreference.subscriberAudioFallbackEnabled
            )
        } else {
            Toggle(
                "Subscriber Audio Fallback".localized,
                isOn: $viewModel.settingsPreference.subscriberAudioFallbackEnabled
            )
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview {
        Form {
            AudioSectionView(viewModel: .preview, isCompactLayout: true)
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Audio Section - Active Call") {
        Form {
            AudioSectionView(viewModel: .preview, isInActiveCall: true, isCompactLayout: true)
        }
        .preferredColorScheme(.dark)
    }
#endif
