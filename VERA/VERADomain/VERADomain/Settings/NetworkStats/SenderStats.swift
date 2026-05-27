//
//  Created by Vonage on 21/05/2026.
//

import Foundation

/// Sender-side estimation metrics received by a subscriber.
///
/// Populated from `OTSenderStats` on `OTSubscriberKitVideoNetworkStats`
/// and `OTSubscriberKitAudioNetworkStats` when the publisher has enabled
/// sender-side statistics (`senderStatsTrack = true`).
public struct SenderStats: Equatable {
    /// Maximum bitrate estimated for the sender connection (bps).
    public let connectionMaxAllocatedBitrate: Int64
    /// Current estimated bandwidth for the sender connection (bps).
    public let connectionEstimatedBandwidth: Int64

    public init(
        connectionMaxAllocatedBitrate: Int64 = 0,
        connectionEstimatedBandwidth: Int64 = 0
    ) {
        self.connectionMaxAllocatedBitrate = connectionMaxAllocatedBitrate
        self.connectionEstimatedBandwidth = connectionEstimatedBandwidth
    }
}
