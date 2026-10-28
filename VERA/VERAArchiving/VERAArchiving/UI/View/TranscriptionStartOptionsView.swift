//
//  Created by Vonage on 26/10/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Lets the user choose the post-call transcription options before starting it.
///
/// Replaces the plain start confirmation for transcriptions. The options apply to the
/// transcription being started and cannot be changed while it runs.
public struct TranscriptionStartOptionsScreen: View {
    @Bindable private var viewModel: ArchiveButtonViewModel

    public init(viewModel: ArchiveButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        TranscriptionStartOptionsView(
            options: $viewModel.transcriptionOptions,
            onStart: viewModel.confirmTranscriptionStart,
            onCancel: viewModel.cancelTranscriptionStart)
    }
}

struct TranscriptionStartOptionsView: View {
    @Binding var options: TranscriptionOptions
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ArchiveKind.transcription.startConfirmationTitle)
                .adaptiveFont(.heading4)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)

            Text(ArchiveKind.transcription.startConfirmationMessage)
                .adaptiveFont(.bodyBase)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $options.hasSummary) {
                Text("Include AI summary", bundle: .veraArchiving)
                    .adaptiveFont(.bodyBase)
            }
            .tint(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
            .accessibilityIdentifier(ArchivingAccessibilityID.transcriptionSummaryToggle)

            HStack(spacing: 12) {
                OutlinedButton(
                    text: Text("Cancel", bundle: .veraArchiving),
                    color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
                    onAction: onCancel
                )
                .accessibilityIdentifier(ArchivingAccessibilityID.transcriptionCancelButton)

                FilledButton(
                    text: Text("Start", bundle: .veraArchiving),
                    onAction: onStart
                )
                .accessibilityIdentifier(ArchivingAccessibilityID.transcriptionConfirmStartButton)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    TranscriptionStartOptionsView(
        options: .constant(.default),
        onStart: {},
        onCancel: {})
}
