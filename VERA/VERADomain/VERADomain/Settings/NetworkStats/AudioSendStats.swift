//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Publisher-side audio statistics (send direction).
///
/// Populated from `OTPublisherKitAudioNetworkStats` via the SDK's
/// `networkStatsDelegate` callback.
public struct AudioSendStats: Equatable {
    /// Total audio packets sent since the stream started.
    public let packetsSent: Int64
    /// Total audio packets lost as reported by the remote endpoint.
    public let packetsLost: Int64
    /// Total audio bytes sent since the stream started.
    public let bytesSent: Int64
    /// Timestamp of this stats sample (seconds since epoch).
    public let timestamp: Double
    /// The actual audio codec negotiated by the SDK (e.g. "opus").
    ///
    /// Populated from the WebRTC RTC stats report. `nil` until the first report arrives.
    public let audioCodec: String?

    public init(
        packetsSent: Int64 = 0,
        packetsLost: Int64 = 0,
        bytesSent: Int64 = 0,
        timestamp: Double = 0,
        audioCodec: String? = nil
    ) {
        self.packetsSent = packetsSent
        self.packetsLost = packetsLost
        self.bytesSent = bytesSent
        self.timestamp = timestamp
        self.audioCodec = audioCodec
    }
}
