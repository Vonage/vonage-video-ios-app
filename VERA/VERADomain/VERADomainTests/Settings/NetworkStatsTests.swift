//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@Suite("Network stats tests")
struct NetworkStatsTests {

    // MARK: - AudioSendStats

    @Test("AudioSendStats default values are zero")
    func audioSendStatsDefaults() {
        let stats = AudioSendStats()

        #expect(stats.packetsSent == 0)
        #expect(stats.packetsLost == 0)
        #expect(stats.bytesSent == 0)
        #expect(stats.timestamp == 0)
        #expect(stats.audioCodec == nil)
    }

    @Test("AudioSendStats custom values")
    func audioSendStatsCustom() {
        let stats = AudioSendStats(
            packetsSent: 1000,
            packetsLost: 5,
            bytesSent: 50000,
            timestamp: 1234567890.0,
            audioCodec: "opus")

        #expect(stats.packetsSent == 1000)
        #expect(stats.packetsLost == 5)
        #expect(stats.bytesSent == 50000)
        #expect(stats.timestamp == 1234567890.0)
        #expect(stats.audioCodec == "opus")
    }

    @Test("AudioSendStats equality")
    func audioSendStatsEquality() {
        let stats1 = AudioSendStats(packetsSent: 100, packetsLost: 2, bytesSent: 5000, timestamp: 1.0)
        let stats2 = AudioSendStats(packetsSent: 100, packetsLost: 2, bytesSent: 5000, timestamp: 1.0)

        #expect(stats1 == stats2)
    }

    @Test("AudioSendStats inequality")
    func audioSendStatsInequality() {
        let stats1 = AudioSendStats(packetsSent: 100)
        let stats2 = AudioSendStats(packetsSent: 200)

        #expect(stats1 != stats2)
    }

    // MARK: - VideoSendStats

    @Test("VideoSendStats default values are zero")
    func videoSendStatsDefaults() {
        let stats = VideoSendStats()

        #expect(stats.packetsSent == 0)
        #expect(stats.packetsLost == 0)
        #expect(stats.bytesSent == 0)
        #expect(stats.timestamp == 0)
        #expect(stats.videoCodec == nil)
    }

    @Test("VideoSendStats custom values")
    func videoSendStatsCustom() {
        let stats = VideoSendStats(
            packetsSent: 5000,
            packetsLost: 10,
            bytesSent: 2_000_000,
            timestamp: 1234567890.0,
            videoCodec: "VP8")

        #expect(stats.packetsSent == 5000)
        #expect(stats.packetsLost == 10)
        #expect(stats.bytesSent == 2_000_000)
        #expect(stats.videoCodec == "VP8")
    }

    @Test("VideoSendStats equality")
    func videoSendStatsEquality() {
        let stats1 = VideoSendStats(packetsSent: 100, videoCodec: "H264")
        let stats2 = VideoSendStats(packetsSent: 100, videoCodec: "H264")

        #expect(stats1 == stats2)
    }

    // MARK: - AudioReceiveStats

    @Test("AudioReceiveStats default values are zero")
    func audioReceiveStatsDefaults() {
        let stats = AudioReceiveStats()

        #expect(stats.packetsReceived == 0)
        #expect(stats.packetsLost == 0)
        #expect(stats.bytesReceived == 0)
        #expect(stats.timestamp == 0)
        #expect(stats.estimatedBandwidth == nil)
    }

    @Test("AudioReceiveStats custom values")
    func audioReceiveStatsCustom() {
        let stats = AudioReceiveStats(
            packetsReceived: 2000,
            packetsLost: 3,
            bytesReceived: 100_000,
            timestamp: 99.9,
            estimatedBandwidth: 128_000)

        #expect(stats.packetsReceived == 2000)
        #expect(stats.packetsLost == 3)
        #expect(stats.bytesReceived == 100_000)
        #expect(stats.timestamp == 99.9)
        #expect(stats.estimatedBandwidth == 128_000)
    }

    @Test("AudioReceiveStats equality")
    func audioReceiveStatsEquality() {
        let stats1 = AudioReceiveStats(packetsReceived: 50, estimatedBandwidth: 64000)
        let stats2 = AudioReceiveStats(packetsReceived: 50, estimatedBandwidth: 64000)

        #expect(stats1 == stats2)
    }

    // MARK: - VideoReceiveStats

    @Test("VideoReceiveStats default values are zero")
    func videoReceiveStatsDefaults() {
        let stats = VideoReceiveStats()

        #expect(stats.packetsReceived == 0)
        #expect(stats.packetsLost == 0)
        #expect(stats.bytesReceived == 0)
        #expect(stats.timestamp == 0)
    }

    @Test("VideoReceiveStats custom values")
    func videoReceiveStatsCustom() {
        let stats = VideoReceiveStats(
            packetsReceived: 10000,
            packetsLost: 50,
            bytesReceived: 5_000_000,
            timestamp: 1234.5)

        #expect(stats.packetsReceived == 10000)
        #expect(stats.packetsLost == 50)
        #expect(stats.bytesReceived == 5_000_000)
        #expect(stats.timestamp == 1234.5)
    }

    @Test("VideoReceiveStats equality")
    func videoReceiveStatsEquality() {
        let stats1 = VideoReceiveStats(packetsReceived: 100, packetsLost: 5)
        let stats2 = VideoReceiveStats(packetsReceived: 100, packetsLost: 5)

        #expect(stats1 == stats2)
    }

    @Test("VideoReceiveStats inequality")
    func videoReceiveStatsInequality() {
        let stats1 = VideoReceiveStats(packetsReceived: 100)
        let stats2 = VideoReceiveStats(packetsReceived: 200)

        #expect(stats1 != stats2)
    }

    // MARK: - NetworkMediaStats

    @Test("NetworkMediaStats empty has all nil")
    func networkMediaStatsEmpty() {
        let stats = NetworkMediaStats.empty

        #expect(stats.sentAudio == nil)
        #expect(stats.sentVideo == nil)
        #expect(stats.receivedAudio == nil)
        #expect(stats.receivedVideo == nil)
    }

    @Test("NetworkMediaStats default init has all nil")
    func networkMediaStatsDefaultInit() {
        let stats = NetworkMediaStats()

        #expect(stats == NetworkMediaStats.empty)
    }

    @Test("NetworkMediaStats with partial data")
    func networkMediaStatsPartialData() {
        let audioStats = AudioSendStats(packetsSent: 100)
        let stats = NetworkMediaStats(sentAudio: audioStats)

        #expect(stats.sentAudio != nil)
        #expect(stats.sentVideo == nil)
        #expect(stats.receivedAudio == nil)
        #expect(stats.receivedVideo == nil)
    }

    @Test("NetworkMediaStats with full data")
    func networkMediaStatsFullData() {
        let stats = NetworkMediaStats(
            sentAudio: AudioSendStats(packetsSent: 100),
            sentVideo: VideoSendStats(packetsSent: 500),
            receivedAudio: AudioReceiveStats(packetsReceived: 200),
            receivedVideo: VideoReceiveStats(packetsReceived: 1000))

        #expect(stats.sentAudio != nil)
        #expect(stats.sentVideo != nil)
        #expect(stats.receivedAudio != nil)
        #expect(stats.receivedVideo != nil)
    }

    @Test("NetworkMediaStats equality")
    func networkMediaStatsEquality() {
        let audio = AudioSendStats(packetsSent: 100)
        let stats1 = NetworkMediaStats(sentAudio: audio)
        let stats2 = NetworkMediaStats(sentAudio: audio)

        #expect(stats1 == stats2)
    }
}
