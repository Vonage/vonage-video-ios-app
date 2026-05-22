//
//  Created by Vonage on 22/2/26.
//

import Combine
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
public final class NetworkStatsCollector: NSObject, StatsCollector {

    // MARK: - Publishers

    private let subject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)

    /// A publisher that emits the latest aggregated network stats snapshot.
    public var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - Publisher State

    /// Last known send-side audio stats.
    private var lastAudioSend: AudioSendStats?
    /// Last known send-side video stats.
    private var lastVideoSend: VideoSendStats?
    /// Last known publisher media link stats.
    private var lastPublisherMediaLinkStats: PublisherMediaLinkStats?
    /// The actual audio codec negotiated by the SDK, extracted from the RTC stats report.
    private var lastAudioCodec: String?
    /// Display name of the local publisher.
    private var lastPublisherName: String = ""

    // MARK: - Per-Subscriber State

    /// Aggregated state for a single subscriber, keyed by connection ID.
    private struct SubscriberState {
        var name: String = ""
        var audioReceive: AudioReceiveStats?
        var videoReceive: VideoReceiveStats?
        var mediaLink: SubscriberMediaLinkStats?
        var audioCodec: String?
        var videoCodec: String?
    }

    /// Per-subscriber state keyed by connection ID.
    private var subscribers: [String: SubscriberState] = [:]
    /// Ordered list of subscriber connection IDs, preserving insertion order.
    private var subscriberOrder: [String] = []

    // MARK: - Reset

    /// Clears all cached stats and emits ``NetworkMediaStats/empty``.
    public func reset() {
        lastAudioSend = nil
        lastVideoSend = nil
        lastPublisherMediaLinkStats = nil
        lastAudioCodec = nil
        lastPublisherName = ""
        subscribers.removeAll()
        subscriberOrder.removeAll()
        subject.send(.empty)
    }

    // MARK: - Subscriber Removal

    /// Removes all cached stats for a subscriber that has disconnected.
    ///
    /// - Parameter connectionId: The connection ID of the subscriber to remove.
    public func removeSubscriber(connectionId: String) {
        subscribers.removeValue(forKey: connectionId)
        subscriberOrder.removeAll { $0 == connectionId }
        emitCurrent()
    }

    // MARK: - RTC Stats Requests

    /// Requests a fresh RTC stats report from the publisher.
    ///
    /// The result arrives asynchronously via the ``publisher(_:rtcStatsReport:)`` delegate method.
    public func requestRtcStats(from publisher: OTPublisherKit) {
        publisher.rtcStatsReportDelegate = self
        publisher.getRtcStatsReport()
    }

    /// Requests a fresh RTC stats report from a subscriber.
    ///
    /// The result arrives asynchronously via the ``subscriber(_:rtcStatsReport:)`` delegate method.
    public func requestRtcStats(from subscriber: OTSubscriberKit) {
        subscriber.rtcStatsReportDelegate = self
        var error: OTError?
        subscriber.getRtcStatsReport(&error)
    }

    // MARK: - OTPublisherKitNetworkStatsDelegate

    /// Handles video send statistics updates from the publisher.
    public func publisher(
        _ publisher: OTPublisherKit,
        videoNetworkStatsUpdated stats: [OTPublisherKitVideoNetworkStats]
    ) {
        guard let first = stats.first else { return }
        lastPublisherName = publisher.name ?? ""

        let layers = first.videoLayers.map { layer in
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
        }

        lastVideoSend = VideoSendStats(
            packetsSent: first.videoPacketsSent,
            packetsLost: first.videoPacketsLost,
            bytesSent: first.videoBytesSent,
            timestamp: first.timestamp,
            videoCodec: layers.first?.codec,
            videoFrameRate: layers.first?.encodedFrameRate ?? 0,
            startTime: first.startTime,
            videoLayers: layers
        )
        emitCurrent()
    }

    /// Handles audio send statistics updates from the publisher.
    public func publisher(
        _ publisher: OTPublisherKit,
        audioNetworkStatsUpdated stats: [OTPublisherKitAudioNetworkStats]
    ) {
        guard let first = stats.first else { return }

        lastAudioSend = AudioSendStats(
            packetsSent: first.audioPacketsSent,
            packetsLost: first.audioPacketsLost,
            bytesSent: first.audioBytesSent,
            timestamp: first.timestamp,
            audioCodec: lastAudioCodec,
            startTime: first.startTime
        )
        emitCurrent()
    }

    // MARK: - Publisher Media Link Stats

    /// Handles publisher media link stats with transport-level metrics.
    public func publisher(
        _ publisher: OTPublisherKit,
        mediaLinkStatsUpdated mediaLinkStats: [OTPublisherKitMediaLinkStats]
    ) {
        guard let first = mediaLinkStats.first else { return }

        lastPublisherMediaLinkStats = PublisherMediaLinkStats(
            transport: mapTransport(first.transport)
        )
        emitCurrent()
    }

    // MARK: - OTSubscriberKitNetworkStatsDelegate

    /// Handles video receive statistics updates from a subscriber.
    public func subscriber(
        _ subscriber: OTSubscriberKit,
        videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats
    ) {
        let connectionId = connectionId(for: subscriber)
        ensureSubscriber(connectionId, subscriber: subscriber)

        let sdkCodec = (stats.codec?.isEmpty == false) ? stats.codec : nil
        let videoCodec = sdkCodec ?? subscribers[connectionId]?.videoCodec

        // Re-request RTC stats until the video codec is resolved.
        if videoCodec == nil {
            requestRtcStats(from: subscriber)
        }

        subscribers[connectionId]?.videoReceive = VideoReceiveStats(
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
        )
        emitCurrent()
    }

    /// Handles audio receive statistics updates from a subscriber.
    public func subscriber(
        _ subscriber: OTSubscriberKit,
        audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats
    ) {
        let connectionId = connectionId(for: subscriber)
        ensureSubscriber(connectionId, subscriber: subscriber)

        let audioCodec = subscribers[connectionId]?.audioCodec

        // Re-request RTC stats until the audio codec is resolved.
        if audioCodec == nil {
            requestRtcStats(from: subscriber)
        }

        subscribers[connectionId]?.audioReceive = AudioReceiveStats(
            packetsReceived: Int64(stats.audioPacketsReceived),
            packetsLost: Int64(stats.audioPacketsLost),
            bytesReceived: Int64(stats.audioBytesReceived),
            timestamp: stats.timestamp,
            audioCodec: audioCodec,
            estimatedBandwidth: nil
        )
        emitCurrent()
    }

    // MARK: - Subscriber Media Link Stats

    /// Handles subscriber media link stats with transport and degradation metrics.
    public func subscriber(
        _ subscriber: OTSubscriberKit,
        mediaLinkStatsUpdated mediaLinkStats: OTSubscriberKitMediaLinkStats
    ) {
        let connectionId = connectionId(for: subscriber)
        ensureSubscriber(connectionId, subscriber: subscriber)

        subscribers[connectionId]?.mediaLink = SubscriberMediaLinkStats(
            transport: mapTransport(mediaLinkStats.transport),
            remotePublisherTransport: mapTransport(mediaLinkStats.remotePublisherTransport),
            networkDegradationSource: mapDegradationSource(mediaLinkStats.networkDegradationSource)
        )
        emitCurrent()
    }

    // MARK: - OTPublisherKitRtcStatsReportDelegate

    /// Handles RTC stats report from the publisher to extract audio codec.
    public func publisher(_ publisher: OTPublisherKit, rtcStatsReport stats: [OTPublisherRtcStats]) {
        for stat in stats {
            extractAudioCodec(from: stat.jsonArrayOfReports)
        }
        emitCurrent()
    }

    // MARK: - OTSubscriberKitRtcStatsReportDelegate

    /// Handles RTC stats report from a subscriber to extract audio and video codecs.
    public func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport jsonArrayString: String) {
        let connId = connectionId(for: subscriber)
        extractSubscriberCodecs(from: jsonArrayString, connectionId: connId)
        emitCurrent()
    }

    // MARK: - Private Helpers

    private func connectionId(for subscriber: OTSubscriberKit) -> String {
        subscriber.stream?.connection.connectionId ?? ""
    }

    private func ensureSubscriber(_ connectionId: String, subscriber: OTSubscriberKit) {
        if subscribers[connectionId] == nil {
            subscribers[connectionId] = SubscriberState(
                name: subscriber.stream?.name ?? ""
            )
        }
    }

    private func mapTransport(_ transport: OTTransportStats) -> TransportStats {
        TransportStats(
            connectionEstimatedBandwidth: transport.connectionEstimatedBandwidth,
            networkCondition: mapNetworkCondition(transport.networkCondition),
            networkConditionReason: mapConditionReason(transport.networkConditionReason)
        )
    }

    private func mapNetworkCondition(_ condition: OTNetworkCondition) -> NetworkCondition {
        switch condition {
        case .critical: .critical
        case .warning: .warning
        case .fair: .fair
        case .good: .good
        case .excellent: .excellent
        default: .unknown
        }
    }

    private func mapConditionReason(_ reason: OTNetworkReason) -> NetworkConditionReason {
        switch reason {
        case .bandwidth: .bandwidth
        case .packetLoss: .packetLoss
        case .networkConditionChange: .networkConditionChange
        default: .none
        }
    }

    private func mapDegradationSource(_ source: OTNetworkDegradationSource) -> NetworkDegradationSource {
        switch source {
        case .local: .local
        case .remote: .remote
        case .bothOrUnclear: .bothOrUnclear
        default: .unknown
        }
    }

    private func mapQualityLimitation(
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

    /// Extracts audio and video codecs from a subscriber's RTC stats JSON report.
    ///
    /// Uses `inbound-rtp` entries to find both codecs for a specific subscriber.
    private func extractSubscriberCodecs(from jsonArrayString: String, connectionId: String) {
        guard let data = jsonArrayString.data(using: .utf8),
            let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return }

        var codecLookup: [String: String] = [:]
        for entry in entries where (entry["type"] as? String) == "codec" {
            if let id = entry["id"] as? String, let mimeType = entry["mimeType"] as? String {
                codecLookup[id] = mimeType
            }
        }

        for entry in entries where (entry["type"] as? String) == "inbound-rtp" {
            guard let codecId = entry["codecId"] as? String,
                let mimeType = codecLookup[codecId],
                let kind = entry["kind"] as? String
            else { continue }
            let codecName = mimeType.components(separatedBy: "/").last ?? mimeType
            switch kind {
            case "audio": subscribers[connectionId]?.audioCodec = codecName
            case "video": subscribers[connectionId]?.videoCodec = codecName
            default: break
            }
        }

        if let existing = subscribers[connectionId]?.audioReceive {
            let audioCodec = subscribers[connectionId]?.audioCodec
            subscribers[connectionId]?.audioReceive = AudioReceiveStats(
                packetsReceived: existing.packetsReceived,
                packetsLost: existing.packetsLost,
                bytesReceived: existing.bytesReceived,
                timestamp: existing.timestamp,
                audioCodec: audioCodec,
                estimatedBandwidth: existing.estimatedBandwidth
            )
        }

        if let existing = subscribers[connectionId]?.videoReceive {
            let videoCodec = subscribers[connectionId]?.videoCodec
            let resolvedCodec =
                (existing.codec?.isEmpty == false)
                ? existing.codec : videoCodec
            subscribers[connectionId]?.videoReceive = VideoReceiveStats(
                packetsReceived: existing.packetsReceived,
                packetsLost: existing.packetsLost,
                bytesReceived: existing.bytesReceived,
                timestamp: existing.timestamp,
                width: existing.width,
                height: existing.height,
                decodedFrameRate: existing.decodedFrameRate,
                bitrate: existing.bitrate,
                totalBitrate: existing.totalBitrate,
                codec: resolvedCodec,
                pauseCount: existing.pauseCount,
                totalPausesDuration: existing.totalPausesDuration,
                freezeCount: existing.freezeCount,
                totalFreezesDuration: existing.totalFreezesDuration
            )
        }
    }

    /// Extracts audio codec from a publisher's RTC stats JSON report.
    ///
    /// Video codec is now obtained directly from `OTPublisherKitVideoLayerStats.codec`,
    /// but audio codec is still extracted from the RTC stats report.
    private func extractAudioCodec(from jsonArrayString: String) {
        guard let data = jsonArrayString.data(using: .utf8),
            let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return }

        var codecLookup: [String: String] = [:]
        for entry in entries where (entry["type"] as? String) == "codec" {
            if let id = entry["id"] as? String, let mimeType = entry["mimeType"] as? String {
                codecLookup[id] = mimeType
            }
        }

        for entry in entries where (entry["type"] as? String) == "outbound-rtp" {
            guard let codecId = entry["codecId"] as? String,
                let mimeType = codecLookup[codecId],
                (entry["kind"] as? String) == "audio"
            else { continue }
            lastAudioCodec = mimeType.components(separatedBy: "/").last ?? mimeType
        }

        if let existing = lastAudioSend {
            lastAudioSend = AudioSendStats(
                packetsSent: existing.packetsSent,
                packetsLost: existing.packetsLost,
                bytesSent: existing.bytesSent,
                timestamp: existing.timestamp,
                audioCodec: lastAudioCodec,
                startTime: existing.startTime
            )
        }
    }

    // MARK: - Emit

    /// Assembles the latest cached stats into a ``NetworkMediaStats`` and emits it.
    private func emitCurrent() {
        // Track new subscribers while preserving existing order.
        for connectionId in subscribers.keys where !subscriberOrder.contains(connectionId) {
            subscriberOrder.append(connectionId)
        }

        let perSubscriber = subscriberOrder.compactMap { connectionId -> SubscriberMediaStats? in
            guard let state = subscribers[connectionId] else { return nil }
            return SubscriberMediaStats(
                subscriberID: connectionId,
                subscriberName: state.name,
                receivedAudio: state.audioReceive,
                receivedVideo: state.videoReceive,
                mediaLinkStats: state.mediaLink
            )
        }

        subject.send(
            NetworkMediaStats(
                publisherName: lastPublisherName,
                sentAudio: lastAudioSend,
                sentVideo: lastVideoSend,
                subscriberStats: perSubscriber,
                publisherMediaLinkStats: lastPublisherMediaLinkStats
            )
        )
    }
}
