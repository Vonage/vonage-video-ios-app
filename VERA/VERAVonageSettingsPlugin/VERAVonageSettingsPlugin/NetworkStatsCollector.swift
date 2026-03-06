//
//  Created by Vonage on 22/2/26.
//

import Combine
import OpenTok
import VERADomain
import VERAVonage

/// Collects network statistics from Vonage SDK delegates and publishes aggregated domain models.
///
/// `NetworkStatsCollector` conforms to both `OTPublisherKitNetworkStatsDelegate` (send stats)
/// and `OTSubscriberKitNetworkStatsDelegate` (receive stats). It maps SDK types into
/// ``NetworkMediaStats`` and publishes updates through a Combine publisher.
///
/// ## Usage
///
/// Assign this object as the `networkStatsDelegate` on both the publisher and each subscriber.
/// When stats are enabled it accumulates the latest send/receive snapshots and merges them
/// into a single ``NetworkMediaStats`` emission.
///
/// - SeeAlso: ``VonageCall``, ``NetworkStatsProvider``
public final class NetworkStatsCollector: NSObject, StatsCollector {

    // MARK: - Publishers

    private let subject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)

    /// A publisher that emits the latest aggregated network stats snapshot.
    public var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - State

    /// Last known send-side audio stats.
    private var lastAudioSend: AudioSendStats?
    /// Last known send-side video stats.
    private var lastVideoSend: VideoSendStats?
    /// Last known receive-side audio stats.
    private var lastAudioReceive: AudioReceiveStats?
    /// Last known receive-side video stats.
    private var lastVideoReceive: VideoReceiveStats?

    /// The actual video codec negotiated by the SDK, extracted from the RTC stats report.
    private var lastVideoCodec: String?
    /// The actual audio codec negotiated by the SDK, extracted from the RTC stats report.
    private var lastAudioCodec: String?
    /// Latest available incoming bandwidth (bps) from ICE candidate-pair RTC stats.
    private var lastEstimatedBandwidth: Int64?

    // MARK: - Reset

    /// Clears all cached stats and emits ``NetworkMediaStats/empty``.
    public func reset() {
        lastAudioSend = nil
        lastVideoSend = nil
        lastAudioReceive = nil
        lastVideoReceive = nil
        lastVideoCodec = nil
        lastAudioCodec = nil
        lastEstimatedBandwidth = nil
        subject.send(.empty)
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
        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
    }

    // MARK: - OTPublisherKitNetworkStatsDelegate

    /// Handles video send statistics updates from the publisher.
    ///
    /// Updates the cached video send stats and emits the aggregated snapshot.
    ///
    /// - Parameters:
    ///   - publisher: The publisher instance sending stats.
    ///   - stats: Array of video network stats (one per subscriber).
    public func publisher(
        _ publisher: OTPublisherKit,
        videoNetworkStatsUpdated stats: [OTPublisherKitVideoNetworkStats]
    ) {
        // Aggregate across all subscribers — use the first entry for simplicity.
        // A multi-subscriber scenario could sum or average these.
        guard let first = stats.first else { return }

        lastVideoSend = VideoSendStats(
            packetsSent: first.videoPacketsSent,
            packetsLost: first.videoPacketsLost,
            bytesSent: first.videoBytesSent,
            timestamp: first.timestamp,
            videoCodec: lastVideoCodec
        )
        emitCurrent()
    }

    /// Handles audio send statistics updates from the publisher.
    ///
    /// Updates the cached audio send stats and emits the aggregated snapshot.
    ///
    /// - Parameters:
    ///   - publisher: The publisher instance sending stats.
    ///   - stats: Array of audio network stats (one per subscriber).
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
            audioCodec: lastAudioCodec
        )
        emitCurrent()
    }

    // MARK: - OTSubscriberKitNetworkStatsDelegate

    /// Handles video receive statistics updates from a subscriber.
    ///
    /// Updates the cached video receive stats and emits the aggregated snapshot.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber instance receiving the stream.
    ///   - stats: The video network statistics.
    public func subscriber(
        _ subscriber: OTSubscriberKit,
        videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats
    ) {
        lastVideoReceive = VideoReceiveStats(
            packetsReceived: UInt64(stats.videoPacketsReceived),
            packetsLost: UInt64(stats.videoPacketsLost),
            bytesReceived: UInt64(stats.videoBytesReceived),
            timestamp: stats.timestamp
        )
        emitCurrent()
    }

    /// Handles audio receive statistics updates from a subscriber.
    ///
    /// Updates the cached audio receive stats and requests RTC stats for bandwidth estimation.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber instance receiving the stream.
    ///   - stats: The audio network statistics.
    public func subscriber(
        _ subscriber: OTSubscriberKit,
        audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats
    ) {
        lastAudioReceive = AudioReceiveStats(
            packetsReceived: Int64(stats.audioPacketsReceived),
            packetsLost: Int64(stats.audioPacketsLost),
            bytesReceived: Int64(stats.audioBytesReceived),
            timestamp: stats.timestamp,
            estimatedBandwidth: lastEstimatedBandwidth
        )
        // Refresh ICE candidate-pair stats so estimatedBandwidth stays current.
        requestRtcStats(from: subscriber)
        emitCurrent()
    }

    // MARK: - OTPublisherKitRtcStatsReportDelegate

    /// Handles RTC stats report from the publisher.
    ///
    /// Extracts codec information from the RTC stats and updates cached values.
    ///
    /// - Parameters:
    ///   - publisher: The publisher providing the stats.
    ///   - stats: Array of RTC stats reports.
    public func publisher(_ publisher: OTPublisherKit, rtcStatsReport stats: [OTPublisherRtcStats]) {
        stats.forEach {
            handleReports($0.jsonArrayOfReports)
        }
        emitCurrent()
    }

    // MARK: - OTSubscriberKitRtcStatsReportDelegate

    /// Handles RTC stats report from a subscriber.
    ///
    /// Extracts estimated bandwidth from ICE candidate-pair stats and updates audio receive stats.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber providing the stats.
    ///   - jsonArrayString: JSON-encoded array of RTC stats entries.
    public func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport jsonArrayString: String) {
        guard let data = jsonArrayString.data(using: .utf8),
            let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return }

        // Find the nominated ICE candidate-pair and extract availableIncomingBitrate.
        for entry in entries where (entry["type"] as? String) == "candidate-pair" {
            if let bitrate = entry["availableIncomingBitrate"] as? Double {
                lastEstimatedBandwidth = Int64(bitrate)
                break
            }
        }

        // Propagate the updated bandwidth into the cached audio receive snapshot.
        if let existing = lastAudioReceive {
            lastAudioReceive = AudioReceiveStats(
                packetsReceived: existing.packetsReceived,
                packetsLost: existing.packetsLost,
                bytesReceived: existing.bytesReceived,
                timestamp: existing.timestamp,
                estimatedBandwidth: lastEstimatedBandwidth
            )
        }
        emitCurrent()
    }

    // MARK: - Private

    /// Parses an RTC stats JSON report and extracts codec information.
    ///
    /// - Parameter jsonArrayString: JSON string containing RTC stats entries.
    private func handleReports(_ jsonArrayString: String) {
        guard let data = jsonArrayString.data(using: .utf8),
            let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return }

        // Build a lookup of codec id → mimeType.
        var codecLookup: [String: String] = [:]
        for entry in entries where (entry["type"] as? String) == "codec" {
            if let id = entry["id"] as? String,
                let mimeType = entry["mimeType"] as? String
            {
                codecLookup[id] = mimeType
            }
        }

        // Find outbound-rtp entries and resolve their codec.
        for entry in entries where (entry["type"] as? String) == "outbound-rtp" {
            guard let codecId = entry["codecId"] as? String,
                let mimeType = codecLookup[codecId]
            else { continue }

            // mimeType is e.g. "video/VP8" or "audio/opus" — extract the codec name.
            let codecName = mimeType.components(separatedBy: "/").last ?? mimeType
            let kind = entry["kind"] as? String ?? entry["mediaType"] as? String

            if kind == "video" {
                lastVideoCodec = codecName
            } else if kind == "audio" {
                lastAudioCodec = codecName
            }
        }

        // Update existing stats objects with the newly extracted codec info
        if let existing = lastVideoSend {
            lastVideoSend = VideoSendStats(
                packetsSent: existing.packetsSent,
                packetsLost: existing.packetsLost,
                bytesSent: existing.bytesSent,
                timestamp: existing.timestamp,
                videoCodec: lastVideoCodec
            )
        }

        if let existing = lastAudioSend {
            lastAudioSend = AudioSendStats(
                packetsSent: existing.packetsSent,
                packetsLost: existing.packetsLost,
                bytesSent: existing.bytesSent,
                timestamp: existing.timestamp,
                audioCodec: lastAudioCodec
            )
        }
    }

    /// Assembles the latest cached stats into a ``NetworkMediaStats`` and emits it.
    private func emitCurrent() {
        subject.send(
            NetworkMediaStats(
                sentAudio: lastAudioSend,
                sentVideo: lastVideoSend,
                receivedAudio: lastAudioReceive,
                receivedVideo: lastVideoReceive
            )
        )
    }
}
