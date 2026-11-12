//
//  Created by Vonage on 12/10/2026.
//

import VERADomain

/// Synchronous domain-value cache and snapshot builder. This is not a synchronization boundary.
/// The collector owns mutation and publishes snapshots on the same callers as before.
struct NetworkStatsState {
    private var lastAudioSend: AudioSendStats?
    private var lastVideoSend: VideoSendStats?
    private var lastPublisherMediaLinkStats: PublisherMediaLinkStats?
    private var lastAudioCodec: String?
    private var lastPublisherName = ""

    private struct SubscriberState {
        var name: String
        var audioReceive: AudioReceiveStats?
        var videoReceive: VideoReceiveStats?
        var mediaLink: SubscriberMediaLinkStats?
        var audioCodec: String?
        var videoCodec: String?
    }

    private var subscribers: [String: SubscriberState] = [:]
    private var subscriberOrder: [String] = []

    var publisherAudioCodec: String? { lastAudioCodec }
    func hasSubscriber(_ id: String) -> Bool { subscribers[id] != nil }
    func subscriberAudioCodec(_ id: String) -> String? { subscribers[id]?.audioCodec }
    func subscriberVideoCodec(_ id: String) -> String? { subscribers[id]?.videoCodec }

    mutating func ensureSubscriber(_ id: String, name: String) {
        if subscribers[id] == nil {
            subscribers[id] = SubscriberState(name: name)
            subscriberOrder.append(id)
        }
    }

    mutating func updatePublisherName(_ name: String) { lastPublisherName = name }
    mutating func updatePublisherAudio(_ value: AudioSendStats) { lastAudioSend = value }
    mutating func updatePublisherVideo(_ value: VideoSendStats) { lastVideoSend = value }
    mutating func updatePublisherMediaLink(_ value: PublisherMediaLinkStats) {
        lastPublisherMediaLinkStats = value
    }
    mutating func updateSubscriberAudio(_ value: AudioReceiveStats, connectionId: String) {
        subscribers[connectionId]?.audioReceive = value
    }
    mutating func updateSubscriberVideo(_ value: VideoReceiveStats, connectionId: String) {
        subscribers[connectionId]?.videoReceive = value
    }
    mutating func updateSubscriberMediaLink(_ value: SubscriberMediaLinkStats, connectionId: String) {
        subscribers[connectionId]?.mediaLink = value
    }

    mutating func reset() {
        lastAudioSend = nil
        lastVideoSend = nil
        lastPublisherMediaLinkStats = nil
        lastAudioCodec = nil
        lastPublisherName = ""
        subscribers.removeAll()
        subscriberOrder.removeAll()
    }

    mutating func removeSubscriber(connectionId: String) {
        subscribers.removeValue(forKey: connectionId)
        subscriberOrder.removeAll { $0 == connectionId }
    }

    mutating func updateSubscriberCodecs(_ codecs: [NetworkStatsCodec], connectionId: String) {
        for codec in codecs {
            switch codec.kind {
            case "audio": subscribers[connectionId]?.audioCodec = codec.name
            case "video": subscribers[connectionId]?.videoCodec = codec.name
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

    mutating func updatePublisherCodecs(_ codecs: [NetworkStatsCodec]) {
        for codec in codecs where codec.kind == "audio" {
            lastAudioCodec = codec.name
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

    var snapshot: NetworkMediaStats {
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

        return NetworkMediaStats(
            publisherName: lastPublisherName,
            sentAudio: lastAudioSend,
            sentVideo: lastVideoSend,
            subscriberStats: perSubscriber,
            publisherMediaLinkStats: lastPublisherMediaLinkStats
        )
    }
}
