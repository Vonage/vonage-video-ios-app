//
//  Created by Vonage on 06/03/2026.
//

import OpenTok

class MockAudioSendStats: OTPublisherKitAudioNetworkStats {
    private let _audioPacketsSent: Int64
    private let _audioPacketsLost: Int64
    private let _audioBytesSent: Int64
    private let _timestamp: Double
    private let _startTime: Double

    init(
        packetsSent: Int64,
        packetsLost: Int64,
        bytesSent: Int64,
        timestamp: Double,
        startTime: Double = 0
    ) {
        _audioPacketsSent = packetsSent
        _audioPacketsLost = packetsLost
        _audioBytesSent = bytesSent
        _timestamp = timestamp
        _startTime = startTime
        super.init()
    }

    override var audioPacketsSent: Int64 { _audioPacketsSent }
    override var audioPacketsLost: Int64 { _audioPacketsLost }
    override var audioBytesSent: Int64 { _audioBytesSent }
    override var timestamp: Double { _timestamp }
    override var startTime: Double { _startTime }
}

class MockVideoSendStats: OTPublisherKitVideoNetworkStats {
    private let _videoPacketsSent: Int64
    private let _videoPacketsLost: Int64
    private let _videoBytesSent: Int64
    private let _timestamp: Double
    private let _startTime: Double
    private let _videoLayers: [OTPublisherKitVideoLayerStats]

    init(
        packetsSent: Int64,
        packetsLost: Int64,
        bytesSent: Int64,
        timestamp: Double,
        startTime: Double = 0,
        videoLayers: [OTPublisherKitVideoLayerStats] = []
    ) {
        _videoPacketsSent = packetsSent
        _videoPacketsLost = packetsLost
        _videoBytesSent = bytesSent
        _timestamp = timestamp
        _startTime = startTime
        _videoLayers = videoLayers
        super.init()
    }

    override var videoPacketsSent: Int64 { _videoPacketsSent }
    override var videoPacketsLost: Int64 { _videoPacketsLost }
    override var videoBytesSent: Int64 { _videoBytesSent }
    override var timestamp: Double { _timestamp }
    override var startTime: Double { _startTime }
    override var videoLayers: [OTPublisherKitVideoLayerStats] { _videoLayers }
}

class MockAudioReceiveStats: OTSubscriberKitAudioNetworkStats {
    private let _audioPacketsReceived: UInt64
    private let _audioPacketsLost: UInt64
    private let _audioBytesReceived: UInt64
    private let _timestamp: Double

    init(packetsReceived: UInt64, packetsLost: UInt64, bytesReceived: UInt64, timestamp: Double) {
        _audioPacketsReceived = packetsReceived
        _audioPacketsLost = packetsLost
        _audioBytesReceived = bytesReceived
        _timestamp = timestamp
        super.init()
    }

    override var audioPacketsReceived: UInt64 { _audioPacketsReceived }
    override var audioPacketsLost: UInt64 { _audioPacketsLost }
    override var audioBytesReceived: UInt64 { _audioBytesReceived }
    override var timestamp: Double { _timestamp }
}

class MockVideoReceiveStats: OTSubscriberKitVideoNetworkStats {
    private let _videoPacketsReceived: UInt64
    private let _videoPacketsLost: UInt64
    private let _videoBytesReceived: UInt64
    private let _timestamp: Double
    private let _width: Int32
    private let _height: Int32
    private let _decodedFrameRate: Double
    private let _bitrate: Int64
    private let _totalBitrate: Int64
    private let _codec: String?
    private let _pauseCount: Int64
    private let _totalPausesDuration: Int64
    private let _freezeCount: Int64
    private let _totalFreezesDuration: Int64
    private let _senderStats: OTSenderStats?

    init(
        packetsReceived: UInt64,
        packetsLost: UInt64,
        bytesReceived: UInt64,
        timestamp: Double,
        width: Int32 = 0,
        height: Int32 = 0,
        decodedFrameRate: Double = 0,
        bitrate: Int64 = 0,
        totalBitrate: Int64 = 0,
        codec: String? = nil,
        pauseCount: Int64 = 0,
        totalPausesDuration: Int64 = 0,
        freezeCount: Int64 = 0,
        totalFreezesDuration: Int64 = 0,
        senderStats: OTSenderStats? = nil
    ) {
        _videoPacketsReceived = packetsReceived
        _videoPacketsLost = packetsLost
        _videoBytesReceived = bytesReceived
        _timestamp = timestamp
        _width = width
        _height = height
        _decodedFrameRate = decodedFrameRate
        _bitrate = bitrate
        _totalBitrate = totalBitrate
        _codec = codec
        _pauseCount = pauseCount
        _totalPausesDuration = totalPausesDuration
        _freezeCount = freezeCount
        _totalFreezesDuration = totalFreezesDuration
        _senderStats = senderStats
        super.init()
    }

    override var videoPacketsReceived: UInt64 { _videoPacketsReceived }
    override var videoPacketsLost: UInt64 { _videoPacketsLost }
    override var videoBytesReceived: UInt64 { _videoBytesReceived }
    override var timestamp: Double { _timestamp }
    override var width: Int32 { _width }
    override var height: Int32 { _height }
    override var decodedFrameRate: Double { _decodedFrameRate }
    override var bitrate: Int64 { _bitrate }
    override var totalBitrate: Int64 { _totalBitrate }
    override var codec: String? { _codec }
    override var pauseCount: Int64 { _pauseCount }
    override var totalPausesDuration: Int64 { _totalPausesDuration }
    override var freezeCount: Int64 { _freezeCount }
    override var totalFreezesDuration: Int64 { _totalFreezesDuration }
    override var senderStats: OTSenderStats? { _senderStats }
}

class MockPublisherRtcStats: OTPublisherRtcStats {
    private var _jsonArrayOfReports: String

    init(jsonArrayOfReports: String) {
        _jsonArrayOfReports = jsonArrayOfReports
        super.init()
    }

    override var jsonArrayOfReports: String {
        get { _jsonArrayOfReports }
        set { _jsonArrayOfReports = newValue }
    }
}
