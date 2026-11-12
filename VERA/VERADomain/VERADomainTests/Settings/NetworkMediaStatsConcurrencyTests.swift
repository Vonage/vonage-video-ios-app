import Testing
import VERADomain

@Suite("Network statistics concurrency")
struct NetworkMediaStatsConcurrencyTests {
    @Test(
        "Empty and populated snapshots retain their values across tasks and actors",
        arguments: [NetworkMediaStats.empty, populatedSnapshot()])
    func snapshotTransfer(_ snapshot: NetworkMediaStats) async {
        let inbox = StatsInbox()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<32 {
                group.addTask { await inbox.append(snapshot) }
            }
        }

        let received = await inbox.values()
        #expect(received.count == 32)
        #expect(received.allSatisfy { $0 == snapshot })
    }

    private static func populatedSnapshot() -> NetworkMediaStats {
        let transport = TransportStats(connectionEstimatedBandwidth: 2_000_000, networkCondition: .good)
        let sender = SenderStats(connectionMaxAllocatedBitrate: 1_000_000, connectionEstimatedBandwidth: 2_000_000)
        let layer = VideoLayerStats(width: 1280, height: 720, encodedFrameRate: 30, bitrate: 900_000, codec: "VP8")
        let subscriber = SubscriberMediaStats(
            subscriberID: "remote", subscriberName: "Remote participant",
            receivedAudio: AudioReceiveStats(packetsReceived: 100, audioCodec: "opus", senderStats: sender),
            receivedVideo: VideoReceiveStats(width: 1280, height: 720, codec: "VP8", senderStats: sender),
            mediaLinkStats: SubscriberMediaLinkStats(
                transport: transport, remotePublisherTransport: transport, networkDegradationSource: .remote)
        )
        return NetworkMediaStats(
            publisherName: "Local participant",
            sentAudio: AudioSendStats(packetsSent: 80, audioCodec: "opus"),
            sentVideo: VideoSendStats(videoCodec: "VP8", videoFrameRate: 30, videoLayers: [layer]),
            subscriberStats: [subscriber], publisherMediaLinkStats: PublisherMediaLinkStats(transport: transport)
        )
    }
}

private actor StatsInbox {
    private var snapshots: [NetworkMediaStats] = []

    func append(_ snapshot: NetworkMediaStats) {
        snapshots.append(snapshot)
    }

    func values() -> [NetworkMediaStats] {
        snapshots
    }
}
