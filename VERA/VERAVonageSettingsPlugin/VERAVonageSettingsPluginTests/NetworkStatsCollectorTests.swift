//
//  Created by Vonage on 05/03/2026.
//

import Foundation
import OpenTok
import Testing
import VERADomain

@testable import VERAVonageSettingsPlugin

@Suite("NetworkStatsCollector Tests")
struct NetworkStatsCollectorTests {

    // MARK: - Initial State Tests

    @Test("Initial state has empty stats")
    func initialStateHasEmptyStats() async {
        let sut = NetworkStatsCollector()
        var receivedStats: [NetworkMediaStats] = []
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats.append(stats)
        }

        await delay()

        #expect(receivedStats.count == 1)
        #expect(receivedStats.first == .empty)

        cancellable.cancel()
    }

    @Test("Publisher emits initial empty value on subscription")
    func publisherEmitsInitialValue() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?

        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        await delay()

        #expect(receivedStats == .empty)

        cancellable.cancel()
    }

    // MARK: - Reset Tests

    @Test("Reset clears stats and emits empty")
    func resetClearsStatsAndEmitsEmpty() async {
        let sut = NetworkStatsCollector()
        var receivedStats: [NetworkMediaStats] = []
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats.append(stats)
        }

        // Add some stats first
        let audioStats = [MockAudioSendStats(packetsSent: 100, packetsLost: 5, bytesSent: 1000, timestamp: 1.0)]
        sut.publisher(MockPublisher(), audioNetworkStatsUpdated: audioStats)

        await delay()

        sut.reset()

        await delay()

        #expect(receivedStats.last == .empty)

        cancellable.cancel()
    }

    // MARK: - Publisher Audio Stats Tests

    @Test("Publisher audio stats update correctly")
    func publisherAudioStatsUpdateCorrectly() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let audioStats = [
            MockAudioSendStats(
                packetsSent: 100,
                packetsLost: 5,
                bytesSent: 1000,
                timestamp: 1.0,
                startTime: 0.5
            )
        ]

        sut.publisher(MockPublisher(), audioNetworkStatsUpdated: audioStats)

        await delay()

        #expect(receivedStats?.sentAudio?.packetsSent == 100)
        #expect(receivedStats?.sentAudio?.packetsLost == 5)
        #expect(receivedStats?.sentAudio?.bytesSent == 1000)
        #expect(receivedStats?.sentAudio?.timestamp == 1.0)
        #expect(receivedStats?.sentAudio?.startTime == 0.5)

        cancellable.cancel()
    }

    @Test("Publisher audio stats handles empty array")
    func publisherAudioStatsHandlesEmptyArray() async {
        let sut = NetworkStatsCollector()
        var updateCount = 0
        let cancellable = sut.statsPublisher.sink { _ in
            updateCount += 1
        }

        await delay()
        let initialCount = updateCount

        sut.publisher(MockPublisher(), audioNetworkStatsUpdated: [])

        await delay()

        // Should not emit when array is empty
        #expect(updateCount == initialCount)

        cancellable.cancel()
    }

    // MARK: - Publisher Video Stats Tests

    @Test("Publisher video stats update correctly with frame rate and start time")
    func publisherVideoStatsUpdateCorrectly() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let videoStats = [
            MockVideoSendStats(
                packetsSent: 200,
                packetsLost: 10,
                bytesSent: 2000,
                timestamp: 2.0,
                startTime: 1.0
            )
        ]

        sut.publisher(MockPublisher(), videoNetworkStatsUpdated: videoStats)

        await delay()

        #expect(receivedStats?.sentVideo?.packetsSent == 200)
        #expect(receivedStats?.sentVideo?.packetsLost == 10)
        #expect(receivedStats?.sentVideo?.bytesSent == 2000)
        #expect(receivedStats?.sentVideo?.timestamp == 2.0)
        #expect(receivedStats?.sentVideo?.startTime == 1.0)

        cancellable.cancel()
    }

    // MARK: - Subscriber Audio Stats Tests

    @Test("Subscriber audio stats update correctly")
    func subscriberAudioStatsUpdateCorrectly() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let audioStats = MockAudioReceiveStats(
            packetsReceived: 150,
            packetsLost: 7,
            bytesReceived: 1500,
            timestamp: 3.0
        )

        sut.subscriber(dummySubscriber, audioNetworkStatsUpdated: audioStats)

        await delay()

        // Backward-compat: subscriber populates subscriberStats
        #expect(receivedStats?.subscriberStats.count == 1)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.packetsReceived == 150)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.packetsLost == 7)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.bytesReceived == 1500)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.timestamp == 3.0)

        cancellable.cancel()
    }

    // MARK: - Subscriber Video Stats Tests

    @Test("Subscriber video stats update with resolution and codec")
    func subscriberVideoStatsUpdateCorrectly() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let videoStats = MockVideoReceiveStats(
            packetsReceived: 250,
            packetsLost: 12,
            bytesReceived: 2500,
            timestamp: 4.0,
            width: 1280,
            height: 720,
            decodedFrameRate: 30.0,
            bitrate: 1_500_000,
            codec: "VP8",
            freezeCount: 2,
            totalFreezesDuration: 500
        )

        sut.subscriber(dummySubscriber, videoNetworkStatsUpdated: videoStats)

        await delay()

        // Per-subscriber stats
        #expect(receivedStats?.subscriberStats.count == 1)
        let sub = receivedStats?.subscriberStats.first
        #expect(sub?.receivedVideo?.packetsReceived == 250)
        #expect(sub?.receivedVideo?.packetsLost == 12)
        #expect(sub?.receivedVideo?.bytesReceived == 2500)
        #expect(sub?.receivedVideo?.timestamp == 4.0)

        #expect(sub?.receivedVideo?.width == 1280)
        #expect(sub?.receivedVideo?.height == 720)
        #expect(sub?.receivedVideo?.decodedFrameRate == 30.0)
        #expect(sub?.receivedVideo?.bitrate == 1_500_000)
        #expect(sub?.receivedVideo?.freezeCount == 2)
        #expect(sub?.receivedVideo?.totalFreezesDuration == 500)

        // Per-subscriber retains the codec
        #expect(sub?.receivedVideo?.codec == "VP8")

        cancellable.cancel()
    }

    // MARK: - RTC Stats Tests for Audio Codec Extraction

    @Test("Publisher RTC stats extracts audio codec")
    func publisherRtcStatsExtractsAudioCodec() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        // First add audio stats
        let audioStats = [
            MockAudioSendStats(
                packetsSent: 50,
                packetsLost: 2,
                bytesSent: 500,
                timestamp: 1.0
            )
        ]
        sut.publisher(MockPublisher(), audioNetworkStatsUpdated: audioStats)

        await delay()

        // Then send RTC stats with codec info
        let rtcStats = MockPublisherRtcStats(
            jsonArrayOfReports: """
                [
                    {"type": "codec", "id": "codec-2", "mimeType": "audio/opus"},
                    {"type": "outbound-rtp", "kind": "audio", "codecId": "codec-2"}
                ]
                """)

        sut.publisher(MockPublisher(), rtcStatsReport: [rtcStats])

        await delay()

        #expect(receivedStats?.sentAudio?.audioCodec == "opus")

        cancellable.cancel()
    }

    @Test("Publisher RTC stats handles malformed JSON")
    func publisherRtcStatsHandlesMalformedJson() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let rtcStats = MockPublisherRtcStats(jsonArrayOfReports: "invalid json")

        sut.publisher(MockPublisher(), rtcStatsReport: [rtcStats])

        await delay()

        // Should still have empty stats, no crash
        #expect(receivedStats == .empty || receivedStats?.sentAudio == nil)

        cancellable.cancel()
    }

    // MARK: - Remove Subscriber Tests

    @Test("Remove subscriber clears per-subscriber stats")
    func removeSubscriberClearsStats() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        // Add subscriber stats (dummySubscriber has connectionId "")
        let audioStats = MockAudioReceiveStats(
            packetsReceived: 100,
            packetsLost: 5,
            bytesReceived: 1000,
            timestamp: 1.0
        )
        sut.subscriber(dummySubscriber, audioNetworkStatsUpdated: audioStats)

        await delay()

        #expect(receivedStats?.subscriberStats.count == 1)

        // Remove the subscriber
        sut.removeSubscriber(connectionId: "")

        await delay()

        #expect(receivedStats?.subscriberStats.isEmpty == true)

        cancellable.cancel()
    }

    // MARK: - Aggregation Tests

    @Test("Stats from multiple sources aggregate correctly")
    func statsFromMultipleSourcesAggregateCorrectly() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        // Add publisher audio
        let audioSendStats = [
            MockAudioSendStats(
                packetsSent: 100,
                packetsLost: 5,
                bytesSent: 1000,
                timestamp: 1.0
            )
        ]
        sut.publisher(MockPublisher(), audioNetworkStatsUpdated: audioSendStats)

        await delay()

        // Add publisher video
        let videoSendStats = [
            MockVideoSendStats(
                packetsSent: 200,
                packetsLost: 10,
                bytesSent: 2000,
                timestamp: 2.0
            )
        ]
        sut.publisher(MockPublisher(), videoNetworkStatsUpdated: videoSendStats)

        await delay()

        // Add subscriber audio
        let audioReceiveStats = MockAudioReceiveStats(
            packetsReceived: 150,
            packetsLost: 7,
            bytesReceived: 1500,
            timestamp: 3.0
        )
        sut.subscriber(dummySubscriber, audioNetworkStatsUpdated: audioReceiveStats)

        await delay()

        // Add subscriber video
        let videoReceiveStats = MockVideoReceiveStats(
            packetsReceived: 250,
            packetsLost: 12,
            bytesReceived: 2500,
            timestamp: 4.0
        )
        sut.subscriber(dummySubscriber, videoNetworkStatsUpdated: videoReceiveStats)

        await delay()

        // Verify all stats are present
        #expect(receivedStats?.sentAudio?.packetsSent == 100)
        #expect(receivedStats?.sentVideo?.packetsSent == 200)

        // Per-subscriber stats
        #expect(receivedStats?.subscriberStats.count == 1)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.packetsReceived == 150)
        #expect(receivedStats?.subscriberStats.first?.receivedVideo?.packetsReceived == 250)

        cancellable.cancel()
    }

    @Test("Subscriber RTC stats extracts audio and video codecs")
    func subscriberRtcStatsExtractsCodecs() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        // First add subscriber audio and video stats so there are existing entries to update.
        let audioStats = MockAudioReceiveStats(
            packetsReceived: 100,
            packetsLost: 5,
            bytesReceived: 1000,
            timestamp: 1.0
        )
        sut.subscriber(dummySubscriber, audioNetworkStatsUpdated: audioStats)

        let videoStats = MockVideoReceiveStats(
            packetsReceived: 200,
            packetsLost: 10,
            bytesReceived: 2000,
            timestamp: 2.0
        )
        sut.subscriber(dummySubscriber, videoNetworkStatsUpdated: videoStats)

        await delay()

        // Then send RTC stats with both audio and video codec info.
        sut.subscriber(
            dummySubscriber,
            rtcStatsReport: """
                [
                    {"type": "codec", "id": "codec-1", "mimeType": "audio/opus"},
                    {"type": "codec", "id": "codec-2", "mimeType": "video/VP8"},
                    {"type": "inbound-rtp", "kind": "audio", "codecId": "codec-1"},
                    {"type": "inbound-rtp", "kind": "video", "codecId": "codec-2"}
                ]
                """)

        await delay()

        let subscriber = receivedStats?.subscriberStats.first
        #expect(subscriber?.receivedAudio?.audioCodec == "opus")
        #expect(subscriber?.receivedAudio?.packetsReceived == 100)
        #expect(subscriber?.receivedVideo?.codec == "VP8")
        #expect(subscriber?.receivedVideo?.packetsReceived == 200)

        cancellable.cancel()
    }

    // MARK: - Publisher Name Tests

    @Test("Publisher name is captured from video stats delegate")
    func publisherNameIsCapturedFromVideoStats() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let publisher = MockPublisher(name: "Alice")

        let videoStats = [
            MockVideoSendStats(
                packetsSent: 100,
                packetsLost: 0,
                bytesSent: 500,
                timestamp: 1.0
            )
        ]
        sut.publisher(publisher, videoNetworkStatsUpdated: videoStats)

        await delay()

        #expect(receivedStats?.publisherName == "Alice")

        cancellable.cancel()
    }

    @Test("Publisher name defaults to empty when nil")
    func publisherNameDefaultsToEmpty() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let publisher = MockPublisher()

        let videoStats = [
            MockVideoSendStats(
                packetsSent: 100,
                packetsLost: 0,
                bytesSent: 500,
                timestamp: 1.0
            )
        ]
        sut.publisher(publisher, videoNetworkStatsUpdated: videoStats)

        await delay()

        #expect(receivedStats?.publisherName == "")

        cancellable.cancel()
    }

    @Test("Reset clears publisher name")
    func resetClearsPublisherName() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let publisher = MockPublisher(name: "Bob")

        let videoStats = [
            MockVideoSendStats(
                packetsSent: 100,
                packetsLost: 0,
                bytesSent: 500,
                timestamp: 1.0
            )
        ]
        sut.publisher(publisher, videoNetworkStatsUpdated: videoStats)

        await delay()

        #expect(receivedStats?.publisherName == "Bob")

        sut.reset()

        await delay()

        #expect(receivedStats?.publisherName == "")

        cancellable.cancel()
    }

    // MARK: - Aggregation Tests

    @Test("Single subscriber audio stats are in subscriberStats")
    func singleSubscriberAudioInSubscriberStats() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let audioStats = MockAudioReceiveStats(
            packetsReceived: 300,
            packetsLost: 15,
            bytesReceived: 3000,
            timestamp: 5.0
        )
        sut.subscriber(dummySubscriber, audioNetworkStatsUpdated: audioStats)

        await delay()

        #expect(receivedStats?.subscriberStats.count == 1)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.packetsReceived == 300)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.packetsLost == 15)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.bytesReceived == 3000)
        #expect(receivedStats?.subscriberStats.first?.receivedAudio?.timestamp == 5.0)

        cancellable.cancel()
    }

    @Test("Single subscriber video stats are in subscriberStats")
    func singleSubscriberVideoInSubscriberStats() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        let videoStats = MockVideoReceiveStats(
            packetsReceived: 500,
            packetsLost: 20,
            bytesReceived: 5000,
            timestamp: 6.0,
            width: 1920,
            height: 1080,
            decodedFrameRate: 60.0,
            bitrate: 3_000_000,
            freezeCount: 1,
            totalFreezesDuration: 200
        )
        sut.subscriber(dummySubscriber, videoNetworkStatsUpdated: videoStats)

        await delay()

        #expect(receivedStats?.subscriberStats.count == 1)
        let sub = receivedStats?.subscriberStats.first
        #expect(sub?.receivedVideo?.packetsReceived == 500)
        #expect(sub?.receivedVideo?.packetsLost == 20)
        #expect(sub?.receivedVideo?.bytesReceived == 5000)
        #expect(sub?.receivedVideo?.width == 1920)
        #expect(sub?.receivedVideo?.height == 1080)
        #expect(sub?.receivedVideo?.decodedFrameRate == 60.0)
        #expect(sub?.receivedVideo?.bitrate == 3_000_000)
        #expect(sub?.receivedVideo?.freezeCount == 1)
        #expect(sub?.receivedVideo?.totalFreezesDuration == 200)

        cancellable.cancel()
    }

    @Test("No subscriber stats when only publisher stats")
    func noSubscriberStatsWhenOnlyPublisher() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        // Only add publisher stats, no subscribers
        let audioStats = [
            MockAudioSendStats(
                packetsSent: 100,
                packetsLost: 5,
                bytesSent: 1000,
                timestamp: 1.0
            )
        ]
        sut.publisher(MockPublisher(), audioNetworkStatsUpdated: audioStats)

        await delay()

        #expect(receivedStats?.subscriberStats.isEmpty == true)

        cancellable.cancel()
    }
}
