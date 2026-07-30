//
//  Created by Vonage on 22/2/26.
//

import SwiftUI
import VERADomain

/// Subscriber list with expandable disclosure groups for each remote participant.
struct SubscribersStatsSection: View {

    let subscribers: [SubscriberMediaStats]
    @Binding var expandedSubscribers: Set<String>

    var body: some View {
        if !subscribers.isEmpty {
            ForEach(subscribers) { subscriber in
                Group {
                    ExpandableParticipantHeaderRow(
                        title: subscriber.subscriberName.isEmpty
                            ? "Subscriber".localized
                            : subscriber.subscriberName,
                        icon: "arrow.down.circle",
                        isExpanded: expandedSubscribers.contains(subscriber.id),
                        onToggle: {
                            if expandedSubscribers.contains(subscriber.id) {
                                expandedSubscribers.remove(subscriber.id)
                            } else {
                                expandedSubscribers.insert(subscriber.id)
                            }
                        }
                    )

                    if expandedSubscribers.contains(subscriber.id) {
                        SubscriberStatsContent(subscriber: subscriber)
                    }
                }
            }
        }
    }
}

// MARK: - Subscriber Stats Content

/// Detail view showing audio, video, and network metrics for a single subscriber.
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
            // Est. Bandwidth con icono de info cuando no disponible
            HStack {
                Text("Est. Bandwidth".localized)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    if mediaLink.transport.isBandwidthUnknown {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    Text(mediaLink.transport.bandwidthFormattedWithUnavailable ?? "-")
                        .monospacedDigit()
                        .fontWeight(.medium)
                }
            }
            if mediaLink.networkDegradationSource != .unknown {
                StatsRow(
                    metric: "Degradation Source".localized,
                    value: SettingsFormatter.formatDegradationSource(mediaLink.networkDegradationSource)
                )
            }
        }
    }
}
