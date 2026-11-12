//
//  Created by Vonage on 12/10/2026.
//

import Testing
import VERADomain

@testable import VERAVonageSettingsPlugin

@Suite("Network statistics state compatibility")
struct NetworkStatsStateTests {
    @Test("Initial state is empty")
    func startsEmpty() {
        let sut = makeSUT()
        #expect(sut.snapshot == .empty)
        #expect(sut.publisherAudioCodec == nil)
    }

    @Test("Snapshots aggregate independent channels without changing publisher name")
    func aggregatesChannels() {
        var sut = makeSUT()
        let audio = AudioSendStats(
            packetsSent: 12,
            bytesSent: 345,
            timestamp: 6,
            startTime: 1)
        let video = VideoSendStats(
            packetsSent: 23,
            videoCodec: "",
            videoFrameRate: 30,
            videoLayers: [
                VideoLayerStats(
                    width: 640,
                    height: 480)
            ])
        let link = PublisherMediaLinkStats(transport: TransportStats(connectionEstimatedBandwidth: 1234))
        sut.updatePublisherAudio(audio)
        sut.updatePublisherVideo(video)
        sut.updatePublisherMediaLink(link)
        #expect(sut.snapshot.publisherName.isEmpty)
        sut.updatePublisherName("Alice")
        sut.ensureSubscriber(
            "remote",
            name: "Bob")
        let receivedAudio = AudioReceiveStats(packetsReceived: 34)
        let receivedVideo = VideoReceiveStats(packetsReceived: 45)
        let receivedLink = SubscriberMediaLinkStats(transport: TransportStats(connectionEstimatedBandwidth: 5678))
        sut.updateSubscriberAudio(
            receivedAudio,
            connectionId: "remote")
        sut.updateSubscriberVideo(
            receivedVideo,
            connectionId: "remote")
        sut.updateSubscriberMediaLink(
            receivedLink,
            connectionId: "remote")
        #expect(
            sut.snapshot
                == NetworkMediaStats(
                    publisherName: "Alice",
                    sentAudio: audio,
                    sentVideo: video,
                    subscriberStats: [
                        SubscriberMediaStats(
                            subscriberID: "remote",
                            subscriberName: "Bob",
                            receivedAudio: receivedAudio,
                            receivedVideo: receivedVideo,
                            mediaLinkStats: receivedLink)
                    ],
                    publisherMediaLinkStats: link))
    }

    @Test("Repeated subscriber updates retain first name and insertion order")
    func preservesFirstNameAndOrder() {
        var sut = makeSUT()
        sut.ensureSubscriber(
            "z",
            name: "First")
        sut.ensureSubscriber(
            "a",
            name: "Second")
        sut.ensureSubscriber(
            "z",
            name: "Renamed")
        sut.updateSubscriberAudio(
            AudioReceiveStats(packetsReceived: 99),
            connectionId: "z")
        #expect(sut.snapshot.subscriberStats.map(\.subscriberID) == ["z", "a"])
        #expect(sut.snapshot.subscriberStats.map(\.subscriberName) == ["First", "Second"])
        #expect(sut.snapshot.subscriberStats.first?.receivedAudio?.packetsReceived == 99)
    }

    @Test("Removed subscribers lose cached codecs and reinsert at the end")
    func removalAndReinsertion() {
        var sut = makeSUT()
        sut.ensureSubscriber(
            "one",
            name: "Old")
        sut.ensureSubscriber(
            "two",
            name: "Other")
        sut.updateSubscriberCodecs(
            [
                NetworkStatsCodec(
                    kind: "audio",
                    name: "opus")
            ],
            connectionId: "one")
        sut.removeSubscriber(connectionId: "one")
        #expect(!sut.hasSubscriber("one"))
        #expect(sut.subscriberAudioCodec("one") == nil)
        sut.ensureSubscriber(
            "one",
            name: "New")
        #expect(sut.snapshot.subscriberStats.map(\.subscriberID) == ["two", "one"])
        #expect(sut.snapshot.subscriberStats.last?.subscriberName == "New")
        #expect(sut.snapshot.subscriberStats.last?.receivedAudio == nil)
    }

    @Test("Unknown subscriber updates and RTC reports never create subscribers")
    func ignoresUnknownSubscribers() {
        var sut = makeSUT()
        sut.updateSubscriberAudio(
            AudioReceiveStats(packetsReceived: 1),
            connectionId: "unknown")
        sut.updateSubscriberVideo(
            VideoReceiveStats(packetsReceived: 2),
            connectionId: "unknown")
        sut.updateSubscriberMediaLink(
            SubscriberMediaLinkStats(),
            connectionId: "unknown")
        sut.updateSubscriberCodecs(
            [
                NetworkStatsCodec(
                    kind: "audio",
                    name: "opus")
            ],
            connectionId: "unknown")
        sut.removeSubscriber(connectionId: "unknown")
        #expect(sut.snapshot == .empty)
        #expect(!sut.hasSubscriber("unknown"))
    }

    @Test("Empty subscriber IDs keep their existing collision behavior")
    func emptyIDsCollide() {
        var sut = makeSUT()
        sut.ensureSubscriber(
            "",
            name: "First")
        sut.ensureSubscriber(
            "",
            name: "Second")
        sut.updateSubscriberAudio(
            AudioReceiveStats(packetsReceived: 1),
            connectionId: "")
        sut.updateSubscriberVideo(
            VideoReceiveStats(packetsReceived: 2),
            connectionId: "")
        #expect(sut.snapshot.subscriberStats.count == 1)
        #expect(sut.snapshot.subscriberStats.first?.subscriberName == "First")
        #expect(sut.snapshot.subscriberStats.first?.receivedAudio?.packetsReceived == 1)
        #expect(sut.snapshot.subscriberStats.first?.receivedVideo?.packetsReceived == 2)
    }

    @Test("Reset clears all values, codecs and subscriber insertion history")
    func resetClearsEverything() {
        var sut = makeSUT()
        sut.updatePublisherName("Alice")
        sut.updatePublisherAudio(AudioSendStats(packetsSent: 12))
        sut.updatePublisherVideo(VideoSendStats(packetsSent: 34))
        sut.updatePublisherMediaLink(PublisherMediaLinkStats())
        sut.updatePublisherCodecs([
            NetworkStatsCodec(
                kind: "audio",
                name: "opus")
        ])
        sut.ensureSubscriber(
            "old",
            name: "Old")
        sut.updateSubscriberCodecs(
            [
                NetworkStatsCodec(
                    kind: "video",
                    name: "VP8")
            ],
            connectionId: "old")
        sut.reset()
        #expect(sut.snapshot == .empty)
        #expect(sut.publisherAudioCodec == nil)
        #expect(sut.subscriberVideoCodec("old") == nil)
        sut.ensureSubscriber(
            "new",
            name: "New")
        sut.ensureSubscriber(
            "old",
            name: "Rejoined")
        #expect(sut.snapshot.subscriberStats.map(\.subscriberID) == ["new", "old"])
    }

    @Test("An earlier snapshot remains unchanged after updates and reset")
    func snapshotsAreValues() {
        var sut = makeSUT()
        sut.ensureSubscriber(
            "one",
            name: "First")
        sut.updateSubscriberAudio(
            AudioReceiveStats(packetsReceived: 12),
            connectionId: "one")
        let earlier = sut.snapshot
        sut.updateSubscriberAudio(
            AudioReceiveStats(packetsReceived: 99),
            connectionId: "one")
        sut.reset()
        #expect(earlier.subscriberStats.first?.receivedAudio?.packetsReceived == 12)
        #expect(sut.snapshot == .empty)
    }

    @Test("Publisher audio codec backpatch preserves counters, timestamps and start time")
    func backpatchesPublisherAudio() {
        var sut = makeSUT()
        sut.updatePublisherAudio(
            AudioSendStats(
                packetsSent: 12,
                packetsLost: 3,
                bytesSent: 456,
                timestamp: 7,
                startTime: 8))
        sut.updatePublisherCodecs([
            NetworkStatsCodec(
                kind: "audio",
                name: "first"),
            NetworkStatsCodec(
                kind: "video",
                name: "VP8"),
            NetworkStatsCodec(
                kind: "audio",
                name: "last"),
        ])
        #expect(sut.publisherAudioCodec == "last")
        #expect(
            sut.snapshot.sentAudio
                == AudioSendStats(
                    packetsSent: 12,
                    packetsLost: 3,
                    bytesSent: 456,
                    timestamp: 7,
                    audioCodec: "last",
                    startTime: 8))
        sut.updatePublisherCodecs([])
        #expect(sut.snapshot.sentAudio?.audioCodec == "last")
    }

    @Test("Codecs cached before media stats are available for subsequent SDK mapping")
    func cachesCodecsWithoutCreatingMediaStats() {
        var sut = makeSUT()
        sut.updatePublisherCodecs([
            NetworkStatsCodec(
                kind: "audio",
                name: "opus")
        ])
        sut.ensureSubscriber(
            "one",
            name: "First")
        sut.updateSubscriberCodecs(
            [
                NetworkStatsCodec(
                    kind: "audio",
                    name: "opus"),
                NetworkStatsCodec(
                    kind: "video",
                    name: "VP9"),
            ],
            connectionId: "one")
        #expect(sut.publisherAudioCodec == "opus")
        #expect(sut.subscriberAudioCodec("one") == "opus")
        #expect(sut.subscriberVideoCodec("one") == "VP9")
        #expect(sut.snapshot.sentAudio == nil)
        #expect(sut.snapshot.subscriberStats.first?.receivedAudio == nil)
        #expect(sut.snapshot.subscriberStats.first?.receivedVideo == nil)
    }

    @Test("Subscriber audio backpatch retains counters and estimated bandwidth")
    func backpatchesSubscriberAudio() {
        var sut = makeSUT()
        sut.ensureSubscriber(
            "one",
            name: "First")
        sut.updateSubscriberAudio(
            AudioReceiveStats(
                packetsReceived: 12,
                packetsLost: 3,
                bytesReceived: 456,
                timestamp: 7,
                estimatedBandwidth: 890),
            connectionId: "one")
        sut.updateSubscriberCodecs(
            [
                NetworkStatsCodec(
                    kind: "audio",
                    name: "opus")
            ],
            connectionId: "one")
        #expect(
            sut.snapshot.subscriberStats.first?.receivedAudio
                == AudioReceiveStats(
                    packetsReceived: 12,
                    packetsLost: 3,
                    bytesReceived: 456,
                    timestamp: 7,
                    audioCodec: "opus",
                    estimatedBandwidth: 890))
    }

    @Test(
        "Nonempty video codec wins over RTC fallback; empty and nil use RTC",
        arguments: ["H264", "", nil] as [String?])
    func backpatchesSubscriberVideo(codec: String?) {
        var sut = makeSUT()
        sut.ensureSubscriber(
            "one",
            name: "First")
        sut.updateSubscriberVideo(
            VideoReceiveStats(
                packetsReceived: 12,
                packetsLost: 3,
                bytesReceived: 456,
                timestamp: 7,
                width: 640,
                height: 480,
                decodedFrameRate: 24,
                bitrate: 1000,
                totalBitrate: 1100,
                codec: codec,
                pauseCount: 2,
                totalPausesDuration: 3000,
                freezeCount: 4,
                totalFreezesDuration: 5000),
            connectionId: "one")
        sut.updateSubscriberCodecs(
            [
                NetworkStatsCodec(
                    kind: "video",
                    name: "VP8")
            ],
            connectionId: "one")
        #expect(
            sut.snapshot.subscriberStats.first?.receivedVideo
                == VideoReceiveStats(
                    packetsReceived: 12,
                    packetsLost: 3,
                    bytesReceived: 456,
                    timestamp: 7,
                    width: 640,
                    height: 480,
                    decodedFrameRate: 24,
                    bitrate: 1000,
                    totalBitrate: 1100,
                    codec: codec == "H264" ? "H264" : "VP8",
                    pauseCount: 2,
                    totalPausesDuration: 3000,
                    freezeCount: 4,
                    totalFreezesDuration: 5000))
    }

    @Test("Valid empty RTC reports still apply the existing backpatch behavior")
    func emptyReportStillBackpatches() {
        var sut = makeSUT()
        sut.ensureSubscriber(
            "one",
            name: "First")
        sut.updateSubscriberCodecs(
            [
                NetworkStatsCodec(
                    kind: "audio",
                    name: "opus")
            ],
            connectionId: "one")
        // Existing backpatch intentionally omits senderStats; mapping changes belong in another PR.
        sut.updateSubscriberAudio(
            AudioReceiveStats(
                audioCodec: "other",
                senderStats: SenderStats()),
            connectionId: "one")
        sut.updateSubscriberVideo(
            VideoReceiveStats(
                codec: "H264",
                senderStats: SenderStats()),
            connectionId: "one")
        sut.updateSubscriberCodecs(
            [],
            connectionId: "one")
        #expect(sut.snapshot.subscriberStats.first?.receivedAudio?.audioCodec == "opus")
        #expect(sut.snapshot.subscriberStats.first?.receivedAudio?.senderStats == nil)
        #expect(sut.snapshot.subscriberStats.first?.receivedVideo?.codec == "H264")
        #expect(sut.snapshot.subscriberStats.first?.receivedVideo?.senderStats == nil)
    }

    private func makeSUT() -> NetworkStatsState { NetworkStatsState() }
}
