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
                timestamp: 1.0
            )
        ]

        sut.publisher(MockPublisher(), audioNetworkStatsUpdated: audioStats)

        await delay()

        #expect(receivedStats?.sentAudio?.packetsSent == 100)
        #expect(receivedStats?.sentAudio?.packetsLost == 5)
        #expect(receivedStats?.sentAudio?.bytesSent == 1000)
        #expect(receivedStats?.sentAudio?.timestamp == 1.0)

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

    @Test("Publisher video stats update correctly")
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
                timestamp: 2.0
            )
        ]

        sut.publisher(MockPublisher(), videoNetworkStatsUpdated: videoStats)

        await delay()

        #expect(receivedStats?.sentVideo?.packetsSent == 200)
        #expect(receivedStats?.sentVideo?.packetsLost == 10)
        #expect(receivedStats?.sentVideo?.bytesSent == 2000)
        #expect(receivedStats?.sentVideo?.timestamp == 2.0)

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

        #expect(receivedStats?.receivedAudio?.packetsReceived == 150)
        #expect(receivedStats?.receivedAudio?.packetsLost == 7)
        #expect(receivedStats?.receivedAudio?.bytesReceived == 1500)
        #expect(receivedStats?.receivedAudio?.timestamp == 3.0)

        cancellable.cancel()
    }

    // MARK: - Subscriber Video Stats Tests

    @Test("Subscriber video stats update correctly")
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
            timestamp: 4.0
        )

        sut.subscriber(dummySubscriber, videoNetworkStatsUpdated: videoStats)

        await delay()

        #expect(receivedStats?.receivedVideo?.packetsReceived == 250)
        #expect(receivedStats?.receivedVideo?.packetsLost == 12)
        #expect(receivedStats?.receivedVideo?.bytesReceived == 2500)
        #expect(receivedStats?.receivedVideo?.timestamp == 4.0)

        cancellable.cancel()
    }

    // MARK: - RTC Stats Tests for Codec Extraction

    @Test("Publisher RTC stats extracts video codec")
    func publisherRtcStatsExtractsVideoCodec() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        // First add video stats
        let videoStats = [
            MockVideoSendStats(
                packetsSent: 100,
                packetsLost: 5,
                bytesSent: 1000,
                timestamp: 1.0
            )
        ]
        sut.publisher(MockPublisher(), videoNetworkStatsUpdated: videoStats)

        await delay()

        // Then send RTC stats with codec info
        let rtcStats = MockPublisherRtcStats(
            jsonArrayOfReports: """
                [
                    {"type": "codec", "id": "codec-1", "mimeType": "video/VP8"},
                    {"type": "outbound-rtp", "kind": "video", "codecId": "codec-1"}
                ]
                """)

        sut.publisher(MockPublisher(), rtcStatsReport: [rtcStats])

        await delay()

        #expect(receivedStats?.sentVideo?.videoCodec == "VP8")

        cancellable.cancel()
    }

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

    // MARK: - Subscriber RTC Stats for Bandwidth Extraction

    @Test("Subscriber RTC stats extracts bandwidth correctly")
    func subscriberRtcStatsExtractsBandwidth() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        // First add audio stats
        let audioStats = MockAudioReceiveStats(
            packetsReceived: 100,
            packetsLost: 5,
            bytesReceived: 1000,
            timestamp: 1.0
        )
        sut.subscriber(dummySubscriber, audioNetworkStatsUpdated: audioStats)

        await delay()

        // Simulate RTC stats callback with bandwidth
        let jsonString = """
            [
                {"type": "candidate-pair", "availableIncomingBitrate": 500000.0}
            ]
            """
        sut.subscriber(dummySubscriber, rtcStatsReport: jsonString)

        await delay()

        #expect(receivedStats?.receivedAudio?.estimatedBandwidth == 500_000)

        cancellable.cancel()
    }

    @Test("Subscriber RTC stats handles malformed JSON")
    func subscriberRtcStatsHandlesMalformedJson() async {
        let sut = NetworkStatsCollector()
        var receivedStats: NetworkMediaStats?
        let cancellable = sut.statsPublisher.sink { stats in
            receivedStats = stats
        }

        sut.subscriber(dummySubscriber, rtcStatsReport: "invalid json")

        await delay()

        // Should not crash
        #expect(receivedStats == .empty || receivedStats != nil)

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

        // Verify all stats are aggregated
        #expect(receivedStats?.sentAudio?.packetsSent == 100)
        #expect(receivedStats?.sentVideo?.packetsSent == 200)
        #expect(receivedStats?.receivedAudio?.packetsReceived == 150)
        #expect(receivedStats?.receivedVideo?.packetsReceived == 250)

        cancellable.cancel()
    }
}
