//
//  Created by Vonage on 22/2/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

enum StatsConstants {
    static let defaultValue = "\u{2014}"
}

/// Coordinator that observes the settings and statistics view models and
/// composes ``StatisticsSectionView`` (pure toggle) with ``StatsLiveSection``
/// (live metrics table).
///
/// When ``statisticsViewModel`` is provided (meeting room) and stats are enabled,
/// a live table of audio/video send/receive metrics is shown below the toggle.
/// When ``statisticsViewModel`` is `nil` (waiting room), only the toggle appears.
struct StatisticsSectionScreen: View {

    @ObservedObject var viewModel: SettingsViewModel
    var statisticsViewModel: StatisticsViewModel?

    var body: some View {
        StatisticsSectionView(
            senderStatsEnabled: $viewModel.settingsPreference.senderStatsEnabled
        )

        if let statisticsViewModel {
            StatsLiveSection(
                settingsViewModel: viewModel,
                statsViewModel: statisticsViewModel
            )
        }
    }
}

// MARK: - StatisticsSectionView

/// Pure presentation component for the stats toggle.
/// Contains no ViewModel references — receives only a binding.
struct StatisticsSectionView: View {

    @Binding var senderStatsEnabled: Bool

    var body: some View {
        Section {
            Toggle("Enable Stats".localized, isOn: $senderStatsEnabled)
        } header: {
            Text("Real-Time Stats".localized)
        } footer: {
            Text(
                "When enabled, real-time network metrics are displayed for the publisher and each subscriber."
                    .localized)
        }
    }
}

// MARK: - StatsLiveSection

/// Dedicated subview that holds `@ObservedObject` references to both view models,
/// so SwiftUI re-renders whenever `senderStatsEnabled` or `stats` change.
///
/// `StatisticsSectionScreen` cannot hold `statisticsViewModel` as `@ObservedObject`
/// because it is optional; extracting it here avoids that limitation.
private struct StatsLiveSection: View {

    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var statsViewModel: StatisticsViewModel

    var body: some View {
        if settingsViewModel.senderStatsEnabled {
            realTimeStatsContent.onAppear {
                statsViewModel.setup()
            }
        } else {
            DisabledStatsView()
        }
    }

    @ViewBuilder
    private var realTimeStatsContent: some View {
        Section {
            PublisherStatsSection(
                stats: statsViewModel.stats,
                isExpanded: $statsViewModel.isPublisherExpanded,
                maxAudioBitrateFormatted: settingsViewModel.maxAudioBitrateFormatted
            )
            SubscribersStatsSection(
                subscribers: statsViewModel.stats.subscriberStats,
                expandedSubscribers: $statsViewModel.expandedSubscribers
            )
        } header: {
            Text("Participants".localized)
        }
    }
}

// MARK: - DisabledStatsView

/// Placeholder shown when stats are disabled, prompting the user to enable them.
private struct DisabledStatsView: View {

    var body: some View {
        Section {
            VStack(spacing: 12) {
                VERACommonUIAsset.Images.chartSolid.swiftUIImage
                    .foregroundStyle(.secondary)
                Text("Enable Stats above to see real-time metrics.".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview("Without Stats") {
        Form {
            StatisticsSectionScreen(
                viewModel: .preview,
                statisticsViewModel: nil
            )
        }
        .preferredColorScheme(.dark)
    }

    #Preview("With Stats Enabled") {
        Form {
            StatisticsSectionScreen(
                viewModel: .previewWithStatsEnabled,
                statisticsViewModel: .placeholder
            )
        }
        .preferredColorScheme(.dark)
    }

    #Preview("With Stats Disabled") {
        Form {
            StatisticsSectionScreen(
                viewModel: .preview,
                statisticsViewModel: .placeholder
            )
        }
        .preferredColorScheme(.dark)
    }
#endif
