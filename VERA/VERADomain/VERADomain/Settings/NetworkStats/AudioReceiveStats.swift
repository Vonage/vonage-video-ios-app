//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Subscriber-side audio statistics (receive direction).
///
/// Populated from `OTSubscriberKitAudioNetworkStats` via the SDK's
/// `networkStatsDelegate` callback, and from the WebRTC RTC stats report
/// via `OTSubscriberKitRtcStatsReportDelegate`.
public struct AudioReceiveStats: Equatable {
    /// Total audio packets received since the stream started.
    public let packetsReceived: Int64
    /// Total audio packets lost in the receive direction.
    public let packetsLost: Int64
    /// Total audio bytes received since the stream started.
    public let bytesReceived: Int64
    /// Timestamp of this stats sample (seconds since epoch).
    public let timestamp: Double
    /// Estimated available incoming bandwidth in bits per second,
    /// derived from the ICE candidate-pair `availableIncomingBitrate` field
    /// in the WebRTC RTC stats report. `nil` until the first RTC stats report arrives.
    public let estimatedBandwidth: Int64?

    public init(
        packetsReceived: Int64 = 0,
        packetsLost: Int64 = 0,
        bytesReceived: Int64 = 0,
        timestamp: Double = 0,
        estimatedBandwidth: Int64? = nil
    ) {
        self.packetsReceived = packetsReceived
        self.packetsLost = packetsLost
        self.bytesReceived = bytesReceived
        self.timestamp = timestamp
        self.estimatedBandwidth = estimatedBandwidth
    }
}
