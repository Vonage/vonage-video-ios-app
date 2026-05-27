//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Subscriber-side video statistics (receive direction).
///
/// Populated from `OTSubscriberKitVideoNetworkStats` via the SDK's
/// `networkStatsDelegate` callback.
public struct VideoReceiveStats: Equatable {
    /// Total video packets received since the stream started.
    public let packetsReceived: UInt64
    /// Total video packets lost in the receive direction.
    public let packetsLost: UInt64
    /// Total video bytes received since the stream started.
    public let bytesReceived: UInt64
    /// Timestamp of this stats sample (seconds since epoch).
    public let timestamp: Double
    /// Decoded frame width in pixels.
    public let width: Int32
    /// Decoded frame height in pixels.
    public let height: Int32
    /// Decoded frames per second.
    public let decodedFrameRate: Double
    /// Video bitrate in bits per second (excluding RTP overhead).
    public let bitrate: Int64
    /// Video bitrate in bits per second (including RTP overhead).
    public let totalBitrate: Int64
    /// Current decoder codec (e.g. "VP8", "H264").
    public let codec: String?
    /// Number of video pauses (>5s since last frame).
    public let pauseCount: Int64
    /// Total pause duration in milliseconds.
    public let totalPausesDuration: Int64
    /// Number of WebRTC-defined freeze events.
    public let freezeCount: Int64
    /// Total freeze duration in milliseconds.
    public let totalFreezesDuration: Int64
    /// Sender-side metrics from the remote publisher, if available.
    public let senderStats: SenderStats?

    public init(
        packetsReceived: UInt64 = 0,
        packetsLost: UInt64 = 0,
        bytesReceived: UInt64 = 0,
        timestamp: Double = 0,
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
        senderStats: SenderStats? = nil
    ) {
        self.packetsReceived = packetsReceived
        self.packetsLost = packetsLost
        self.bytesReceived = bytesReceived
        self.timestamp = timestamp
        self.width = width
        self.height = height
        self.decodedFrameRate = decodedFrameRate
        self.bitrate = bitrate
        self.totalBitrate = totalBitrate
        self.codec = codec
        self.pauseCount = pauseCount
        self.totalPausesDuration = totalPausesDuration
        self.freezeCount = freezeCount
        self.totalFreezesDuration = totalFreezesDuration
        self.senderStats = senderStats
    }
}
