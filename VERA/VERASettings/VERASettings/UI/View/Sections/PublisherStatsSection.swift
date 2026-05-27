//
//  Created by Vonage on 22/2/26.
//

import SwiftUI
import VERADomain

/// Publisher stats disclosure group showing audio, video, and network metrics.
struct PublisherStatsSection: View {

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
