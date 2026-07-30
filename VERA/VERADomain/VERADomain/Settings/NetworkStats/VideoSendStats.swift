//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Publisher-side video statistics (send direction).
///
/// Populated from `OTPublisherKitVideoNetworkStats` via the SDK's
/// `networkStatsDelegate` callback. The SDK delivers an array of these
/// (one per subscriber); values here represent the aggregate/first entry.
public struct VideoSendStats: Equatable {
    /// Total video packets sent since the stream started.
    public let packetsSent: Int64
    /// Total video packets lost as reported by the remote endpoint.
    public let packetsLost: Int64
    /// Total video bytes sent since the stream started.
    public let bytesSent: Int64
    /// Timestamp of this stats sample (seconds since epoch).
    public let timestamp: Double
    /// The actual video codec negotiated by the SDK (e.g. "VP8", "H264", "VP9").
    ///
    /// Extracted from the first video layer's codec field.
    public let videoCodec: String?
    /// Current average video frame rate (fps).
    public let videoFrameRate: Double
    /// Timestamp (ms since epoch) from which cumulative totals started accumulating.
    public let startTime: Double
    /// Per-layer statistics for simulcast or SVC video encoding.
    public let videoLayers: [VideoLayerStats]

    public init(
        packetsSent: Int64 = 0,
        packetsLost: Int64 = 0,
        bytesSent: Int64 = 0,
        timestamp: Double = 0,
        videoCodec: String? = nil,
        videoFrameRate: Double = 0,
        startTime: Double = 0,
        videoLayers: [VideoLayerStats] = []
    ) {
        self.packetsSent = packetsSent
        self.packetsLost = packetsLost
        self.bytesSent = bytesSent
        self.timestamp = timestamp
        self.videoCodec = videoCodec
        self.videoFrameRate = videoFrameRate
        self.startTime = startTime
        self.videoLayers = videoLayers
    }
}
