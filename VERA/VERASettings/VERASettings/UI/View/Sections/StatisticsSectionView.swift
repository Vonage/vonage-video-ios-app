//
//  Created by Vonage on 22/2/26.
//

import SwiftUI

private enum StatsConstants {
    static let defaultValue = "\u{2014}"
}

/// Stats section content: sender stats toggle + optional real-time stats table.
///
/// When ``statisticsViewModel`` is provided (meeting room) and stats are enabled,
/// a live table of audio/video send/receive metrics is shown below the toggle.
/// When ``statisticsViewModel`` is `nil` (waiting room), only the toggle appears.
struct StatisticsSectionView: View {

    @ObservedObject var viewModel: SettingsViewModel
    var statisticsViewModel: StatisticsViewModel?

    var body: some View {
        Section {
            Toggle("Enable Sender Stats".localized, isOn: $viewModel.settingsPreference.senderStatsEnabled)
        } header: {
            Text("Collection".localized)
        } footer: {
            Text(
                "When enabled, the SDK collects and reports real-time network metrics for the local publisher."
                    .localized)
        }

        if let statisticsViewModel {
            StatsLiveSection(statsViewModel: statisticsViewModel, settingsViewModel: viewModel)
        }
    }
}

// MARK: - StatsLiveSection

/// Dedicated subview that holds `@ObservedObject` references to both view models,
/// so SwiftUI re-renders whenever `isStatsEnabled` or `stats` change.
///
/// `StatisticsSectionView` cannot hold `statisticsViewModel` as `@ObservedObject`
/// because it is optional; extracting it here avoids that limitation.
private struct StatsLiveSection: View {

    @ObservedObject var statsViewModel: StatisticsViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel

    private var estimatedBandwidthFormatted: String? {
        SettingsFormatter.formatBandwidth(statsViewModel.stats.receivedAudio?.estimatedBandwidth)
    }

    var body: some View {
        // Read the live toggle — reacts instantly without writing to the repo.
        // The repo (and SDK collection) is only updated when the user taps Save.
        if settingsViewModel.senderStatsEnabled {
            realTimeStatsContent.onAppear {
                statsViewModel.setup()
            }
        } else {
            disabledStatsContent
        }
    }

    // MARK: - Disabled Prompt

    private var disabledStatsContent: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("Enable Sender Stats above to see real-time metrics.".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Real-Time Stats Table

    @ViewBuilder
    private var realTimeStatsContent: some View {
        Section("Audio".localized) {
            statsRow(
                metric: "Packets Sent".localized,
                value: statsViewModel.stats.sentAudio?.packetsSentFormmatted
            )
            statsRow(
                metric: "Packets Lost (Send)".localized,
                value: statsViewModel.stats.sentAudio?.packetsLostFormmatted
            )
            statsRow(
                metric: "Bytes Sent".localized,
                value: statsViewModel.stats.sentAudio?.bytesSentFormmatted
            )
            statsRow(
                metric: "Packets Received".localized,
                value: statsViewModel.stats.receivedAudio?.packetsReceivedFormmatted
            )
            statsRow(
                metric: "Packets Lost (Receive)".localized,
                value: statsViewModel.stats.receivedAudio?.packetsLostFormmatted
            )
            statsRow(
                metric: "Bytes Received".localized,
                value: statsViewModel.stats.receivedAudio?.bytesReceivedFormmatted
            )
            statsRow(
                metric: "Max Allocated Bitrate".localized,
                value: settingsViewModel.maxAudioBitrateFormatted
            )
            statsRow(
                metric: "Estimated Bandwidth".localized,
                value: statsViewModel.estimatedBandwidthFormatted
            )
        }

        Section("Video".localized) {
            statsRow(
                metric: "Packets Sent".localized,
                value: statsViewModel.stats.sentVideo?.packetsSentFormmatted
            )
            statsRow(
                metric: "Packets Lost (Send)".localized,
                value: statsViewModel.stats.sentVideo?.packetsLostFormmatted
            )
            statsRow(
                metric: "Bytes Sent".localized,
                value: statsViewModel.stats.sentVideo?.bytesSentFormmatted
            )
            statsRow(
                metric: "Packets Received".localized,
                value: statsViewModel.stats.receivedVideo?.packetsReceivedFormmatted
            )
            statsRow(
                metric: "Packets Lost (Receive)".localized,
                value: statsViewModel.stats.receivedVideo?.packetsLostFormmatted
            )
            statsRow(
                metric: "Bytes Received".localized,
                value: statsViewModel.stats.receivedVideo?.bytesReceivedFormmatted
            )
        }
    }

    // MARK: - Row

    private func statsRow(
        metric: String,
        value: String?,
        defaultValue: String = StatsConstants.defaultValue
    ) -> some View {
        HStack {
            Text(metric)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? defaultValue)
                .monospacedDigit()
                .fontWeight(.medium)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Without Stats") {
    Form {
        StatisticsSectionView(
            viewModel: .preview,
            statisticsViewModel: nil
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("With Stats Enabled") {
    Form {
        StatisticsSectionView(
            viewModel: .previewWithStatsEnabled,
            statisticsViewModel: .placeholder
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("With Stats Disabled") {
    Form {
        StatisticsSectionView(
            viewModel: .preview,
            statisticsViewModel: .placeholder
        )
    }
    .preferredColorScheme(.dark)
}
#endif
