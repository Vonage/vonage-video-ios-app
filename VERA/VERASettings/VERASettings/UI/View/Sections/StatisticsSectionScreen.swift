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
/// When ``statisticsViewModel`` is provided (meeting room), the live publisher and
/// subscriber stats sections are shown below the toggles.
/// When ``statisticsViewModel`` is `nil` (waiting room), only the toggles appear.
struct StatisticsSectionScreen: View {

    @ObservedObject var viewModel: SettingsViewModel
    var statisticsViewModel: StatisticsViewModel?
    var isCompactLayout: Bool = false
    var showsSectionHeaders: Bool = true

    var body: some View {
        if isCompactLayout {
            compactBody
        } else {
            regularBody
        }
    }

    @ViewBuilder
    private var compactBody: some View {
        Section {
            statsToggleContent
            if statisticsViewModel != nil {
                Text("Cannot be changed during an active call".localized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Stats".localized)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)
        }

        if let statisticsViewModel {
            Section {
                ParticipantsStatsSection(
                    settingsViewModel: viewModel,
                    statsViewModel: statisticsViewModel
                )
            } header: {
                Text("Participant stats".localized)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)
            }
        }
    }

    @ViewBuilder
    private var statsToggleContent: some View {
        if statisticsViewModel != nil {
            LockedToggleRow(
                title: "Enable extra stats for subscribers".localized,
                value: viewModel.settingsPreference.senderStatsEnabled
            )
        } else {
            Toggle(
                "Enable extra stats for subscribers".localized,
                isOn: $viewModel.settingsPreference.senderStatsEnabled
            )
        }
    }

    @ViewBuilder
    private var overlayToggleContent: some View {
        Toggle("Show Overlay Stats".localized, isOn: $viewModel.settingsPreference.statsOverlayEnabled)
    }

    @ViewBuilder
    private var regularBody: some View {
        StatisticsSectionContent(
            senderStatsEnabled: $viewModel.settingsPreference.senderStatsEnabled,
            showsSectionHeader: showsSectionHeaders,
            isSenderStatsDisabled: statisticsViewModel != nil
        )

        if let statisticsViewModel {
            Section {
                ParticipantsStatsSection(
                    settingsViewModel: viewModel,
                    statsViewModel: statisticsViewModel
                )
            } header: {
                Text("Participant stats".localized)
            }
        }
    }
}

// MARK: - StatisticsSectionView

/// Pure presentation component for the stats toggle.
/// Contains no ViewModel references — receives only a binding.
struct StatisticsSectionContent: View {

    @Binding var senderStatsEnabled: Bool
    let showsSectionHeader: Bool
    let isSenderStatsDisabled: Bool

    var body: some View {
        Section {
            statsToggleContent
        } header: {
            if showsSectionHeader {
                Text("Stats".localized)
            }
        }
    }

    @ViewBuilder
    private var statsToggleContent: some View {
        if isSenderStatsDisabled {
            LockedToggleRow(
                title: "Enable extra stats for subscribers".localized,
                value: senderStatsEnabled
            )
        } else {
            Toggle("Enable extra stats for subscribers".localized, isOn: $senderStatsEnabled)
        }
    }

}

// MARK: - ParticipantsStatsSection

/// Dedicated subview that holds `@ObservedObject` references to both view models,
/// so SwiftUI re-renders only the participant details when expansion state changes.
///
/// `StatisticsSectionScreen` cannot hold `statisticsViewModel` as `@ObservedObject`
/// because it is optional; extracting it here avoids that limitation.
private struct ParticipantsStatsSection: View {

    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var statsViewModel: StatisticsViewModel

    @ViewBuilder
    var body: some View {
        PublisherStatsSection(
            stats: statsViewModel.stats,
            isExpanded: $statsViewModel.isPublisherExpanded,
            maxAudioBitrateFormatted: settingsViewModel.maxAudioBitrateFormatted
        )
        .onAppear {
            statsViewModel.setup()
        }
        SubscribersStatsSection(
            subscribers: statsViewModel.stats.subscriberStats,
            expandedSubscribers: $statsViewModel.expandedSubscribers
        )
    }
}

// MARK: - Previews

#if DEBUG
    #Preview("Without Stats") {
        Form {
            StatisticsSectionScreen(
                viewModel: .preview,
                statisticsViewModel: nil,
                showsSectionHeaders: true
            )
        }
        .preferredColorScheme(.dark)
    }

    #Preview("With Stats Enabled") {
        Form {
            StatisticsSectionScreen(
                viewModel: .previewWithStatsEnabled,
                statisticsViewModel: .placeholder,
                showsSectionHeaders: true
            )
        }
        .preferredColorScheme(.dark)
    }

    #Preview("With Stats Disabled") {
        Form {
            StatisticsSectionScreen(
                viewModel: .preview,
                statisticsViewModel: .placeholder,
                showsSectionHeaders: true
            )
        }
        .preferredColorScheme(.dark)
    }
#endif
