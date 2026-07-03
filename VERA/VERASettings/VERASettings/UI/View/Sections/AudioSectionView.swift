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

    // Local Double mirror of the Int32 bitrate so Slider can bind to it.
    @State private var audioBitrateSlider = Double(AudioSettingsConstants.defaultAudioBitrate)

    var body: some View {
        Section {
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
        } header: {
            Text("Audio Bitrate".localized)
        } footer: {
            Text(
                "Controls the maximum audio encoding bitrate sent to the session. Higher values improve quality but use more bandwidth."
                    .localized)
        }

        Section {
            Toggle("Enable Opus Dtx".localized, isOn: $viewModel.settingsPreference.opusDtxEnabled)
        } header: {
            Text("Discontinuous Transmission".localized)
        } footer: {
            Text(
                "Enabling Opus DTX can reduce bandwidth usage in streams that have long periods of silence."
                    .localized)
        }

        Section {
            Toggle(
                "Publisher Audio Fallback".localized, isOn: $viewModel.settingsPreference.publisherAudioFallbackEnabled)
        } header: {
            Text("Publisher Fallback".localized)
        } footer: {
            Text(
                "When enabled, your video stops rendering on other devices during poor network conditions to preserve audio."
                    .localized)
        }

        Section {
            Toggle(
                "Subscriber Audio Fallback".localized,
                isOn: $viewModel.settingsPreference.subscriberAudioFallbackEnabled)
        } header: {
            Text("Subscriber Fallback".localized)
        } footer: {
            Text(
                "When enabled, you receive audio only from other participants during poor network conditions.".localized
            )
        }

        Section {
            Button("Test Speaker".localized) {
                viewModel.showSpeakerTestDialog = true
            }
        } header: {
            Text("Speaker Test".localized)
        } footer: {
            Text("Play a short tone to verify your current audio output is working.".localized)
        }
        .confirmationDialog(
            "Test Speaker".localized,
            isPresented: $viewModel.showSpeakerTestDialog,
            titleVisibility: .visible
        ) {
            Button("Play Sound".localized) { viewModel.testSpeaker() }
            Button("Cancel".localized, role: .cancel) {}
        } message: {
            Text("A short tone will play through your current audio output.".localized)
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview {
        Form {
            AudioSectionView(viewModel: .preview)
        }
        .preferredColorScheme(.dark)
    }
#endif
