//
//  Created by Vonage on 06/03/2026.
//

import OpenTok

class MockAudioSendStats: OTPublisherKitAudioNetworkStats {
    private let _audioPacketsSent: Int64
    private let _audioPacketsLost: Int64
    private let _audioBytesSent: Int64
    private let _timestamp: Double
    
    init(packetsSent: Int64, packetsLost: Int64, bytesSent: Int64, timestamp: Double) {
        _audioPacketsSent = packetsSent
        _audioPacketsLost = packetsLost
        _audioBytesSent = bytesSent
        _timestamp = timestamp
        super.init()
    }
    
    override var audioPacketsSent: Int64 { _audioPacketsSent }
    override var audioPacketsLost: Int64 { _audioPacketsLost }
    override var audioBytesSent: Int64 { _audioBytesSent }
    override var timestamp: Double { _timestamp }
}

class MockVideoSendStats: OTPublisherKitVideoNetworkStats {
    private let _videoPacketsSent: Int64
    private let _videoPacketsLost: Int64
    private let _videoBytesSent: Int64
    private let _timestamp: Double
    
    init(packetsSent: Int64, packetsLost: Int64, bytesSent: Int64, timestamp: Double) {
        _videoPacketsSent = packetsSent
        _videoPacketsLost = packetsLost
        _videoBytesSent = bytesSent
        _timestamp = timestamp
        super.init()
    }
    
    override var videoPacketsSent: Int64 { _videoPacketsSent }
    override var videoPacketsLost: Int64 { _videoPacketsLost }
    override var videoBytesSent: Int64 { _videoBytesSent }
    override var timestamp: Double { _timestamp }
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
    
    init(packetsReceived: UInt64, packetsLost: UInt64, bytesReceived: UInt64, timestamp: Double) {
        _videoPacketsReceived = packetsReceived
        _videoPacketsLost = packetsLost
        _videoBytesReceived = bytesReceived
        _timestamp = timestamp
        super.init()
    }
    
    override var videoPacketsReceived: UInt64 { _videoPacketsReceived }
    override var videoPacketsLost: UInt64 { _videoPacketsLost }
    override var videoBytesReceived: UInt64 { _videoBytesReceived }
    override var timestamp: Double { _timestamp }
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
