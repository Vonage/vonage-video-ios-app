//
//  Created by Vonage on 22/2/26.
//

import Combine
import Foundation
import OpenTok
import VERADomain
import VERAVonage

/// Collects network statistics from Vonage SDK delegates and publishes aggregated domain models.
///
/// `NetworkStatsCollector` conforms to both `OTPublisherKitNetworkStatsDelegate` (send stats),
/// `OTSubscriberKitNetworkStatsDelegate` (receive stats), and the media link stats delegates
/// for transport-level metrics. It maps SDK types into ``NetworkMediaStats`` and publishes
/// updates through a Combine publisher.
///
/// ## Usage
///
/// Assign this object as the `networkStatsDelegate`
/// on both the publisher and each subscriber. When stats are enabled it accumulates
/// the latest send/receive snapshots per subscriber and merges them into a single
/// ``NetworkMediaStats`` emission.
///
/// - SeeAlso: ``VonageCall``, ``NetworkStatsProvider``
@MainActor
public final class NetworkStatsCollector: NSObject, StatsCollector {

    // MARK: - Publishers

    private let subject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)

    /// A publisher that emits the latest aggregated network stats snapshot.
    public var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    /// Holds domain values only; SDK mapping, requests and synchronous emission stay here.
    nonisolated private let storage: NetworkStatsStorage
    private var subscribers: [String: OTSubscriberKit] = [:]

    public override init() {
        storage = NetworkStatsStorage()
        super.init()
        storage.setHandler { [weak self] snapshot, retryIDs in
            guard let self else { return }
            self.subject.send(snapshot)
            for id in retryIDs {
                if let subscriber = self.subscribers[id] { self.requestRtcStats(from: subscriber) }
            }
        }
    }

    // MARK: - Reset

    /// Clears all cached stats and emits ``NetworkMediaStats/empty``.
    public func reset() {
        subscribers.removeAll()
        storage.reset()
    }

    // MARK: - Subscriber Removal

    /// Removes all cached stats for a subscriber that has disconnected.
    ///
    /// - Parameter connectionId: The connection ID of the subscriber to remove.
    public func removeSubscriber(connectionId: String) {
        subscribers[connectionId] = nil
        storage.removeSubscriber(connectionId: connectionId)
    }

    // MARK: - RTC Stats Requests

    /// Requests a fresh RTC stats report from the publisher.
    ///
    /// The result arrives asynchronously via the ``publisher(_:rtcStatsReport:)`` delegate method.
    public func requestRtcStats(from publisher: OTPublisherKit) {
        storage.registerPublisher(ObjectIdentifier(publisher))
        publisher.rtcStatsReportDelegate = self
        publisher.getRtcStatsReport()
    }

    /// Requests a fresh RTC stats report from a subscriber.
    ///
    /// The result arrives asynchronously via the ``subscriber(_:rtcStatsReport:)`` delegate method.
    public func requestRtcStats(from subscriber: OTSubscriberKit) {
        let id = connectionId(for: subscriber)
        subscribers[id] = subscriber
        storage.registerSubscriber(ObjectIdentifier(subscriber), connectionId: id)
        subscriber.rtcStatsReportDelegate = self
        var error: OTError?
        subscriber.getRtcStatsReport(&error)
    }

    // MARK: - OTPublisherKitNetworkStatsDelegate

    /// Handles video send statistics updates from the publisher.
    nonisolated public func publisher(
        _ publisher: OTPublisherKit,
        videoNetworkStatsUpdated stats: [OTPublisherKitVideoNetworkStats]
    ) {
        guard let first = stats.first else { return }
        storage.update(source: ObjectIdentifier(publisher)) { state, retryIDs in
            state.updatePublisherName(publisher.name ?? "")

            let layers = mergedVideoLayers(from: stats)
            let primaryLayer = first.videoLayers.first

            state.updatePublisherVideo(
                VideoSendStats(
                    packetsSent: first.videoPacketsSent,
                    packetsLost: first.videoPacketsLost,
                    bytesSent: first.videoBytesSent,
                    timestamp: first.timestamp,
                    videoCodec: primaryLayer?.codec ?? layers.first?.codec,
                    videoFrameRate: primaryLayer?.encodedFrameRate ?? layers.first?.encodedFrameRate ?? 0,
                    startTime: first.startTime,
                    videoLayers: layers
                ))
        }
    }

    /// Handles audio send statistics updates from the publisher.
    nonisolated public func publisher(
        _ publisher: OTPublisherKit,
        audioNetworkStatsUpdated stats: [OTPublisherKitAudioNetworkStats]
    ) {
        guard let first = stats.first else { return }
        storage.update(source: ObjectIdentifier(publisher)) { state, retryIDs in

            state.updatePublisherAudio(
                AudioSendStats(
                    packetsSent: first.audioPacketsSent,
                    packetsLost: first.audioPacketsLost,
                    bytesSent: first.audioBytesSent,
                    timestamp: first.timestamp,
                    audioCodec: state.publisherAudioCodec,
                    startTime: first.startTime
                ))
        }
    }

    // MARK: - Publisher Media Link Stats

    /// Handles publisher media link stats with transport-level metrics.
    nonisolated public func publisher(
        _ publisher: OTPublisherKit,
        mediaLinkStatsUpdated mediaLinkStats: [OTPublisherKitMediaLinkStats]
    ) {
        guard let first = mediaLinkStats.first else { return }
        storage.update(source: ObjectIdentifier(publisher)) { state, retryIDs in

            state.updatePublisherMediaLink(
                PublisherMediaLinkStats(
                    transport: mapTransport(first.transport)
                ))
        }
    }

    // MARK: - OTSubscriberKitNetworkStatsDelegate

    /// Handles video receive statistics updates from a subscriber.
    nonisolated public func subscriber(
        _ subscriber: OTSubscriberKit,
        videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats
    ) {
        let connectionId = connectionId(for: subscriber)
        storage.update(source: ObjectIdentifier(subscriber), connectionId: connectionId) { state, retryIDs in
            state.ensureSubscriber(connectionId, name: subscriber.stream?.name ?? "")

            let sdkCodec = (stats.codec?.isEmpty == false) ? stats.codec : nil
            let videoCodec = sdkCodec ?? state.subscriberVideoCodec(connectionId)

            // Re-request RTC stats until the video codec is resolved.
            if videoCodec == nil {
                retryIDs.insert(connectionId)
            }

            state.updateSubscriberVideo(
                VideoReceiveStats(
                    packetsReceived: UInt64(stats.videoPacketsReceived),
                    packetsLost: UInt64(stats.videoPacketsLost),
                    bytesReceived: UInt64(stats.videoBytesReceived),
                    timestamp: stats.timestamp,
                    width: stats.width,
                    height: stats.height,
                    decodedFrameRate: stats.decodedFrameRate,
                    bitrate: stats.bitrate,
                    totalBitrate: stats.totalBitrate,
                    codec: videoCodec,
                    pauseCount: stats.pauseCount,
                    totalPausesDuration: stats.totalPausesDuration,
                    freezeCount: stats.freezeCount,
                    totalFreezesDuration: stats.totalFreezesDuration
                ), connectionId: connectionId)
        }
    }

    /// Handles audio receive statistics updates from a subscriber.
    nonisolated public func subscriber(
        _ subscriber: OTSubscriberKit,
        audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats
    ) {
        let connectionId = connectionId(for: subscriber)
        storage.update(source: ObjectIdentifier(subscriber), connectionId: connectionId) { state, retryIDs in
            state.ensureSubscriber(connectionId, name: subscriber.stream?.name ?? "")

            let audioCodec = state.subscriberAudioCodec(connectionId)

            // Re-request RTC stats until the audio codec is resolved.
            if audioCodec == nil {
                retryIDs.insert(connectionId)
            }

            state.updateSubscriberAudio(
                AudioReceiveStats(
                    packetsReceived: Int64(stats.audioPacketsReceived),
                    packetsLost: Int64(stats.audioPacketsLost),
                    bytesReceived: Int64(stats.audioBytesReceived),
                    timestamp: stats.timestamp,
                    audioCodec: audioCodec,
                    estimatedBandwidth: nil
                ), connectionId: connectionId)
        }
    }

    // MARK: - Subscriber Media Link Stats

    /// Handles subscriber media link stats with transport and degradation metrics.
    nonisolated public func subscriber(
        _ subscriber: OTSubscriberKit,
        mediaLinkStatsUpdated mediaLinkStats: OTSubscriberKitMediaLinkStats
    ) {
        let connectionId = connectionId(for: subscriber)
        storage.update(source: ObjectIdentifier(subscriber), connectionId: connectionId) { state, retryIDs in
            state.ensureSubscriber(connectionId, name: subscriber.stream?.name ?? "")

            state.updateSubscriberMediaLink(
                SubscriberMediaLinkStats(
                    transport: mapTransport(mediaLinkStats.transport),
                    remotePublisherTransport: mapTransport(mediaLinkStats.remotePublisherTransport),
                    networkDegradationSource: mapDegradationSource(mediaLinkStats.networkDegradationSource)
                ), connectionId: connectionId)
        }
    }

    // MARK: - OTPublisherKitRtcStatsReportDelegate

    /// Handles RTC stats report from the publisher to extract audio codec.
    nonisolated public func publisher(_ publisher: OTPublisherKit, rtcStatsReport stats: [OTPublisherRtcStats]) {
        storage.update(source: ObjectIdentifier(publisher)) { state, retryIDs in
            for stat in stats {
                if let codecs = NetworkStatsCodecReport.parse(stat.jsonArrayOfReports, direction: .outbound) {
                    state.updatePublisherCodecs(codecs)
                }
            }
        }
    }

    // MARK: - OTSubscriberKitRtcStatsReportDelegate

    /// Handles RTC stats report from a subscriber to extract audio and video codecs.
    nonisolated public func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport jsonArrayString: String) {
        let connectionId = connectionId(for: subscriber)
        storage.update(source: ObjectIdentifier(subscriber), connectionId: connectionId) { state, retryIDs in
            if let codecs = NetworkStatsCodecReport.parse(jsonArrayString, direction: .inbound) {
                state.updateSubscriberCodecs(codecs, connectionId: connectionId)
            }
        }
    }

    // MARK: - Private Helpers

    nonisolated private func connectionId(for subscriber: OTSubscriberKit) -> String {
        subscriber.stream?.connection.connectionId ?? ""
    }

    nonisolated private func mapTransport(_ transport: OTTransportStats) -> TransportStats {
        TransportStats(
            connectionEstimatedBandwidth: transport.connectionEstimatedBandwidth,
            networkCondition: mapNetworkCondition(transport.networkCondition),
            networkConditionReason: mapConditionReason(transport.networkConditionReason)
        )
    }

    nonisolated private func mapNetworkCondition(_ condition: OTNetworkCondition) -> NetworkCondition {
        switch condition {
        case .critical: .critical
        case .warning: .warning
        case .fair: .fair
        case .good: .good
        case .excellent: .excellent
        default: .unknown
        }
    }

    nonisolated private func mapConditionReason(_ reason: OTNetworkReason) -> NetworkConditionReason {
        switch reason {
        case .bandwidth: .bandwidth
        case .packetLoss: .packetLoss
        case .networkConditionChange: .networkConditionChange
        default: .none
        }
    }

    nonisolated private func mapDegradationSource(_ source: OTNetworkDegradationSource) -> NetworkDegradationSource {
        switch source {
        case .local: .local
        case .remote: .remote
        case .bothOrUnclear: .bothOrUnclear
        default: .unknown
        }
    }

    nonisolated private func mapQualityLimitation(
        _ reason: OTPublisherVideoEventReason
    ) -> QualityLimitationReason {
        switch reason {
        case .qualityDegradationBandwidth: .bandwidth
        case .qualityDegradationCPU: .cpu
        case .codecChange: .codec
        case .resolutionChange: .resolution
        default: .none
        }
    }

    private struct VideoLayerKey: Hashable {
        let width: Int32
        let height: Int32
        let scalabilityMode: String
    }

    nonisolated private func mergedVideoLayers(
        from stats: [OTPublisherKitVideoNetworkStats]
    ) -> [VideoLayerStats] {
        var layersByKey: [VideoLayerKey: (timestamp: Double, layer: VideoLayerStats)] = [:]

        for videoStats in stats {
            for layer in videoStats.videoLayers {
                let key = VideoLayerKey(
                    width: layer.width,
                    height: layer.height,
                    scalabilityMode: layer.scalabilityMode ?? ""
                )
                if let existing = layersByKey[key], existing.timestamp > videoStats.timestamp {
                    continue
                }
                layersByKey[key] = (
                    videoStats.timestamp,
                    VideoLayerStats(
                        width: layer.width,
                        height: layer.height,
                        encodedFrameRate: layer.encodedFrameRate,
                        bitrate: layer.bitrate,
                        totalBitrate: layer.totalBitrate,
                        codec: layer.codec,
                        scalabilityMode: layer.scalabilityMode,
                        qualityLimitationReason: mapQualityLimitation(layer.qualityLimitationReason)
                    )
                )
            }
        }

        return layersByKey.values.map(\.layer).sorted {
            let lhsPixels = Int64($0.width) * Int64($0.height)
            let rhsPixels = Int64($1.width) * Int64($1.height)
            if lhsPixels != rhsPixels {
                return lhsPixels < rhsPixels
            }
            return ($0.scalabilityMode ?? "") < ($1.scalabilityMode ?? "")
        }
    }

}
