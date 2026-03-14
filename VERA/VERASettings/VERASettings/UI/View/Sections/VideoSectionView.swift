//
//  Created by Vonage on 22/2/26.
//

import SwiftUI
import VERACommonUI

private enum VideoUIConstants {
    static let spaceBetweenComponents = 8.0
}

private enum VideoConstants {
    // OT SDK valid range: 5000 – 10 000 000 bps.
    static let videoBitrateRange: ClosedRange<Double> = 5_000...10_000_000
    static let videoBitrateStep: Double = 50_000
    static let currentVideoBitrateStep: Double = 500_000
}

/// Video section content: bitrate stepper, codec picker, frame rate and resolution pickers.
///
/// Returns `Section` blocks intended to be embedded inside a parent `Form`.
struct VideoSectionView: View {

    @ObservedObject var viewModel: SettingsViewModel
    @State private var sliderValue: Double = VideoConstants.currentVideoBitrateStep

    var body: some View {
        Section {
            Picker("Bitrate Preset".localized, selection: $viewModel.settingsPreference.videoBitratePreset) {
                ForEach(SettingsVideoBitratePreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }

            if viewModel.videoBitratePreset == .custom {
                VStack(alignment: .leading, spacing: VideoUIConstants.spaceBetweenComponents) {
                    Text("Max Video Bitrate".localized(args: viewModel.videoBitrateFormatted))
                        .font(.subheadline)

                    Slider(
                        value: $sliderValue,
                        in: VideoConstants.videoBitrateRange,
                        step: VideoConstants.videoBitrateStep
                    )
                    .onChange(of: sliderValue) { newValue in
                        viewModel.setMaxVideorate(newValue)
                    }
                    .onAppear {
                        sliderValue = Double(viewModel.customMaxVideoBitrate)
                    }

                    HStack {
                        Text("5 kbps".localized)
                        Spacer()
                        Text("10 Mbps".localized)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Bitrate".localized)
        } footer: {
            Text(viewModel.videoBitratePreset.footerDescription)
        }

        Section {
            Picker("Mode".localized, selection: $viewModel.settingsPreference.codecPreference.mode) {
                ForEach(SettingsCodecMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.codecMode == .manual {
                ForEach(viewModel.orderedCodecs) { codec in
                    HStack {
                        VERACommonUIAsset.Images.menuSolid.swiftUIImage
                            .foregroundStyle(.secondary)
                        Text(codec.displayName)
                        Spacer()
                        Text(priorityLabel(for: codec))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onMove { source, destination in
                    viewModel.sortingCodec(
                        source: source,
                        destination: destination
                    )
                }
            }
        } header: {
            Text("Codec".localized)
        } footer: {
            Text(viewModel.codecMode.footerDescription)
        }
        #if os(iOS)
            .environment(\.editMode, .constant(.active))
        #endif
        Section("Frame Rate".localized) {
            Picker("Frame Rate".localized, selection: $viewModel.settingsPreference.videoFrameRate) {
                ForEach(SettingsVideoFrameRate.allCases) { fps in
                    Text(fps.displayName).tag(fps)
                }
            }
        }

        Section("Resolution".localized) {
            Picker("Resolution".localized, selection: $viewModel.settingsPreference.videoResolution) {
                ForEach(SettingsVideoResolution.allCases) { res in
                    Text(res.displayName).tag(res)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Priority label for a codec row (e.g. "1st", "2nd", "3rd").
    private func priorityLabel(for codec: SettingsVideoCodec) -> String {
        guard let index = viewModel.orderedCodecs.firstIndex(of: codec) else { return "" }
        return switch index {
        case 0: "1st".localized
        case 1: "2nd".localized
        case 2: "3rd".localized
        default: ""
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview("Video Section") {
        Form {
            VideoSectionView(viewModel: .preview)
        }
        .preferredColorScheme(.dark)
    }
#endif
