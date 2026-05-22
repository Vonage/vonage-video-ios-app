//
//  Created by Vonage on 22/2/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

private enum StatsConstants {
    static let defaultValue = "\u{2014}"
}

extension String {
    fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
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
            Toggle("Enable Stats".localized, isOn: $viewModel.settingsPreference.senderStatsEnabled)
        } header: {
            Text("Real-Time Stats".localized)
        } footer: {
            Text(
                "When enabled, real-time network metrics are displayed for the publisher and each subscriber."
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

    var body: some View {
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

    // MARK: - Real-Time Stats Table

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

// MARK: - Publisher Stats Section

private struct PublisherStatsSection: View {

    let stats: NetworkMediaStats
    @Binding var isExpanded: Bool
    let maxAudioBitrateFormatted: String?

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            StatsSectionHeader("Audio".localized)
            publisherAudioGroup
            StatsSectionHeader("Video".localized)
            publisherVideoGroup
            StatsSectionHeader("Network".localized)
            publisherTransportGroup
        } label: {
            let name =
                stats.publisherName.isEmpty
                ? "Publisher".localized : stats.publisherName
            HStack(spacing: 6) {
                Label(name, systemImage: "arrow.up.circle")
                    .fontWeight(.semibold)
                Text("You".localized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var publisherAudioGroup: some View {
        let audio = stats.sentAudio
        StatsRow(metric: "Codec".localized, value: audio?.audioCodec?.nilIfEmpty?.uppercased())
        StatsRow(metric: "Packets Sent".localized, value: audio?.packetsSentFormmatted)
        StatsRow(metric: "Packets Lost".localized, value: audio?.packetsLostFormmatted)
        StatsRow(metric: "Bytes Sent".localized, value: audio?.bytesSentFormmatted)
        StatsRow(metric: "Max Bitrate Title".localized, value: maxAudioBitrateFormatted)
    }

    @ViewBuilder
    private var publisherVideoGroup: some View {
        let video = stats.sentVideo
        StatsRow(metric: "Codec".localized, value: video?.videoCodec?.nilIfEmpty)
        StatsRow(metric: "Frame Rate".localized, value: video?.videoFrameRateFormatted)
        StatsRow(metric: "Packets Sent".localized, value: video?.packetsSentFormmatted)
        StatsRow(metric: "Packets Lost".localized, value: video?.packetsLostFormmatted)
        StatsRow(metric: "Bytes Sent".localized, value: video?.bytesSentFormmatted)
        publisherVideoLayersGroup
    }

    @ViewBuilder
    private var publisherVideoLayersGroup: some View {
        let layers = SettingsFormatter.sortedByResolution(stats.sentVideo?.videoLayers ?? [])
        if layers.count > 1 {
            StatsSectionHeader("Simulcast")
            ForEach(Array(layers.enumerated()), id: \.offset) { index, layer in
                StatsSubHeader(SettingsFormatter.qualityLabel(index: index, count: layers.count))
                videoLayerRows(layer)
            }
        } else if let layer = layers.first {
            videoLayerRows(layer)
        }
    }

    @ViewBuilder
    private func videoLayerRows(_ layer: VideoLayerStats) -> some View {
        StatsRow(
            metric: "Resolution".localized,
            value: SettingsFormatter.formatResolution(width: layer.width, height: layer.height)
        )
        StatsRow(
            metric: "Frame Rate".localized,
            value: SettingsFormatter.formatFrameRate(layer.encodedFrameRate)
        )
        StatsRow(
            metric: "Bitrate".localized,
            value: SettingsFormatter.formatBandwidth(Int64(layer.bitrate))
        )
        if layer.qualityLimitationReason != .none {
            StatsRow(
                metric: "Quality Limitation".localized,
                value: SettingsFormatter.formatQualityLimitation(layer.qualityLimitationReason)
            )
        }
    }

    @ViewBuilder
    private var publisherTransportGroup: some View {
        if let transport = stats.publisherMediaLinkStats?.transport {
            StatsRow(metric: "Network Condition".localized, value: transport.conditionFormatted)
            StatsRow(metric: "Est. Bandwidth".localized, value: transport.bandwidthFormatted)
        }
    }
}

// MARK: - Subscribers Stats Section

private struct SubscribersStatsSection: View {

    let subscribers: [SubscriberMediaStats]
    @Binding var expandedSubscribers: Set<String>

    var body: some View {
        if !subscribers.isEmpty {
            ForEach(subscribers) { subscriber in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSubscribers.contains(subscriber.id) },
                        set: { expanded in
                            if expanded {
                                expandedSubscribers.insert(subscriber.id)
                            } else {
                                expandedSubscribers.remove(subscriber.id)
                            }
                        }
                    )
                ) {
                    SubscriberStatsContent(subscriber: subscriber)
                } label: {
                    let name =
                        subscriber.subscriberName.isEmpty
                        ? "Subscriber".localized : subscriber.subscriberName
                    Label(name, systemImage: "arrow.down.circle")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Subscriber Stats Content

private struct SubscriberStatsContent: View {

    let subscriber: SubscriberMediaStats

    var body: some View {
        if subscriber.receivedAudio != nil {
            StatsSectionHeader("Audio".localized)
        }
        audioGroup
        if subscriber.receivedVideo != nil {
            StatsSectionHeader("Video".localized)
        }
        videoGroup
        if subscriber.mediaLinkStats != nil {
            StatsSectionHeader("Network".localized)
        }
        transportGroup
    }

    @ViewBuilder
    private var audioGroup: some View {
        if let audio = subscriber.receivedAudio {
            StatsRow(metric: "Codec".localized, value: audio.audioCodec?.nilIfEmpty?.uppercased())
            StatsRow(metric: "Packets Recv".localized, value: audio.packetsReceivedFormmatted)
            StatsRow(metric: "Packets Lost".localized, value: audio.packetsLostFormmatted)
            StatsRow(metric: "Bytes Recv".localized, value: audio.bytesReceivedFormmatted)
        }
    }

    @ViewBuilder
    private var videoGroup: some View {
        if let video = subscriber.receivedVideo {
            StatsRow(metric: "Resolution".localized, value: video.resolutionFormatted)
            StatsRow(metric: "Decoded FPS".localized, value: video.decodedFrameRateFormatted)
            StatsRow(metric: "Codec".localized, value: video.codec?.nilIfEmpty)
            StatsRow(metric: "Bitrate".localized, value: video.bitrateFormatted)
            StatsRow(metric: "Packets Recv".localized, value: video.packetsReceivedFormmatted)
            StatsRow(metric: "Packets Lost".localized, value: video.packetsLostFormmatted)
            StatsRow(metric: "Bytes Recv".localized, value: video.bytesReceivedFormmatted)
            if video.freezeCount > 0 {
                StatsRow(metric: "Freezes".localized, value: video.freezeFormatted)
            }
            if video.pauseCount > 0 {
                StatsRow(metric: "Pauses".localized, value: video.pauseFormatted)
            }
        }
    }

    @ViewBuilder
    private var transportGroup: some View {
        if let mediaLink = subscriber.mediaLinkStats {
            StatsRow(
                metric: "Network Condition".localized,
                value: mediaLink.transport.conditionFormatted
            )
            StatsRow(
                metric: "Est. Bandwidth".localized,
                value: mediaLink.transport.bandwidthFormatted
            )
            if mediaLink.networkDegradationSource != .unknown {
                StatsRow(
                    metric: "Degradation Source".localized,
                    value: SettingsFormatter.formatDegradationSource(mediaLink.networkDegradationSource)
                )
            }
        }
    }
}

// MARK: - Shared Row Components

private struct StatsSectionHeader: View {

    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            #if os(iOS)
                .listRowBackground(Color(.systemGroupedBackground))
            #endif
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
            .listRowSeparator(.hidden)
    }
}

private struct StatsSubHeader: View {

    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .listRowSeparator(.hidden)
    }
}

private struct StatsRow: View {

    let metric: String
    let value: String?
    var defaultValue: String = StatsConstants.defaultValue

    var body: some View {
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
