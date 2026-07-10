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
    private let isInActiveCall: Bool
    private let isCompactLayout: Bool
    @State private var sliderValue: Double = VideoConstants.currentVideoBitrateStep

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
            bitrateContent
            SettingsDivider()
            degradationContent
            SettingsDivider()
            Text("Preferred Video Codec".localized)
                .font(.headline)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
            codecContent
            SettingsDivider()
            if isInActiveCall {
                ActiveCallWarningText()
            }
            frameRateContent
            SettingsDivider()
            if isInActiveCall {
                ActiveCallWarningText()
            }
            resolutionContent
            if isInActiveCall {
                ActiveCallWarningText()
            }
        }
    }

    @ViewBuilder
    private var regularBody: some View {
        Section {
            bitrateContent
        } header: {
            Text("Bitrate".localized)
        } footer: {
            Text(viewModel.videoBitratePreset.footerDescription)
        }

        Section {
            degradationContent
        } header: {
            Text("Degradation Preference".localized)
        } footer: {
            Text(viewModel.settingsPreference.degradationPreference.footerDescription)
        }

        Section {
            codecContent
        } header: {
            Text("Preferred Video Codec".localized)
        } footer: {
            ActiveCallFooter(isInActiveCall: isInActiveCall, description: viewModel.codecMode.footerDescription)
        }
        #if os(iOS)
            .environment(\.editMode, .constant(.active))
        #endif
        Section {
            frameRateContent
        } header: {
            Text("Frame Rate".localized)
        } footer: {
            if isInActiveCall {
                ActiveCallWarningText()
            }
        }

        Section {
            resolutionContent
        } header: {
            Text("Resolution".localized)
        } footer: {
            if isInActiveCall {
                ActiveCallWarningText()
            }
        }
    }

    @ViewBuilder
    private var bitrateContent: some View {
        Picker("Bitrate Preset".localized, selection: $viewModel.settingsPreference.videoBitratePreset) {
            ForEach(SettingsVideoBitratePreset.allCases) { preset in
                Text(preset.displayName).tag(preset)
            }
        }
        .accessibilityIdentifier(SettingsAccessibilityID.videoBitratePicker)

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
    }

    @ViewBuilder
    private var degradationContent: some View {
        Picker(
            "Degradation Preference".localized,
            selection: $viewModel.settingsPreference.degradationPreference
        ) {
            ForEach(SettingsDegradationPreference.allCases) { preference in
                Text(preference.displayName).tag(preference)
            }
        }
        .accessibilityIdentifier(SettingsAccessibilityID.videoDegradationPicker)
    }

    @ViewBuilder
    private var codecContent: some View {
        if isInActiveCall {
            LockedValueSection(
                title: "Mode".localized,
                value: viewModel.codecMode.displayName
            )
            .accessibilityIdentifier(SettingsAccessibilityID.codecModeLocked)

            if viewModel.codecMode == .manual {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.orderedCodecs) { codec in
                        codecRow(codec)
                    }
                }
            }
        } else {
            Picker("Mode".localized, selection: $viewModel.settingsPreference.codecPreference.mode) {
                ForEach(SettingsCodecMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(SettingsAccessibilityID.codecModePicker)

            if viewModel.codecMode == .manual {
                manualCodecList
            }
        }
    }

    @ViewBuilder
    private var manualCodecList: some View {
        ManualCodecReorderView(
            orderedCodecs: viewModel.orderedCodecs,
            priorityLabel: priorityLabel(for:),
            onMove: viewModel.sortingCodec(source:destination:)
        )
    }

    @ViewBuilder
    private func codecRow(_ codec: SettingsVideoCodec) -> some View {
        HStack {
            VERACommonUIAsset.Images.menuSolid.swiftUIImage
                .foregroundStyle(.secondary)
            Text(codec.displayName)
            Spacer()
            Text(priorityLabel(for: codec))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var frameRateContent: some View {
        if isInActiveCall {
            LockedValueSection(
                title: "Frame Rate".localized,
                value: viewModel.settingsPreference.videoFrameRate.displayName
            )
            .accessibilityIdentifier(SettingsAccessibilityID.frameRateLocked)
        } else {
            Picker("Frame Rate".localized, selection: $viewModel.settingsPreference.videoFrameRate) {
                ForEach(SettingsVideoFrameRate.allCases) { fps in
                    Text(fps.displayName).tag(fps)
                }
            }
            .accessibilityIdentifier(SettingsAccessibilityID.frameRatePicker)
        }
    }

    @ViewBuilder
    private var resolutionContent: some View {
        if isInActiveCall {
            LockedValueSection(
                title: "Resolution".localized,
                value: viewModel.settingsPreference.videoResolution.displayName
            )
            .accessibilityIdentifier(SettingsAccessibilityID.resolutionLocked)
        } else {
            Picker("Resolution".localized, selection: $viewModel.settingsPreference.videoResolution) {
                ForEach(SettingsVideoResolution.allCases) { res in
                    Text(res.displayName).tag(res)
                }
            }
            .accessibilityIdentifier(SettingsAccessibilityID.resolutionPicker)
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
            VideoSectionView(viewModel: .preview, isCompactLayout: true)
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Video Section - Active Call") {
        Form {
            VideoSectionView(viewModel: .preview, isInActiveCall: true, isCompactLayout: true)
        }
        .preferredColorScheme(.dark)
    }
#endif
