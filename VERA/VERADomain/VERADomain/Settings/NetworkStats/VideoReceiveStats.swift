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

    public init(
        packetsReceived: UInt64 = 0,
        packetsLost: UInt64 = 0,
        bytesReceived: UInt64 = 0,
        timestamp: Double = 0
    ) {
        self.packetsReceived = packetsReceived
        self.packetsLost = packetsLost
        self.bytesReceived = bytesReceived
        self.timestamp = timestamp
    }
}
