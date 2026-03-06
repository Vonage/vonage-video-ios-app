//
//  Created by Vonage on 22/2/26.
//

import SwiftUI
import VERACommonUI

private enum AudioConstatnts {
    // OT SDK valid range: 6000 – 510 000 bps.
    static let audioBitrateRange: ClosedRange<Double> = 6_000...510_000
    static let audioBitrateStep: Double = 2_000
    static let currentAudioBitrateStep: Double = 40_000
}

/// Audio section content: audio bitrate slider and fallback toggles.
///
/// Returns `Section` blocks intended to be embedded inside a parent `Form`.
struct AudioSectionView: View {

    @ObservedObject var viewModel: SettingsViewModel

    // Local Double mirror of the Int32 bitrate so Slider can bind to it.
    @State private var audioBitrateSlider: Double = AudioConstatnts.currentAudioBitrateStep

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Max Audio Bitrate".localized(args: viewModel.maxAudioBitrateFormatted))
                    .font(.subheadline)

                Slider(
                    value: $audioBitrateSlider,
                    in: AudioConstatnts.audioBitrateRange,
                    step: AudioConstatnts.audioBitrateStep
                )
                .onChange(of: audioBitrateSlider) { newValue in
                    viewModel.setMaxAudioBitrate(newValue)
                }
                .onAppear {
                    audioBitrateSlider = Double(viewModel.maxAudioBitrate)
                }

                HStack {
                    Text("6 kbps".localized)
                    Spacer()
                    Text("510 kbps".localized)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("Audio Bitrate".localized)
        } footer: {
            Text(
                "Controls the maximum audio encoding bitrate sent to the session. Higher values improve quality but use more bandwidth."
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
