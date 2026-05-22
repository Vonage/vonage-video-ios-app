//
//  Created by Vonage on 21/05/2026.
//

import Foundation

/// Transport-level network metrics for a connection.
///
/// Populated from `OTTransportStats` delivered via the SDK's
/// media link stats delegates.
public struct TransportStats: Equatable {
    /// Estimated available connection bandwidth in bits per second.
    public let connectionEstimatedBandwidth: Int64
    /// Current network condition score.
    public let networkCondition: NetworkCondition
    /// Primary reason impacting the network condition.
    public let networkConditionReason: NetworkConditionReason

    public init(
        connectionEstimatedBandwidth: Int64 = 0,
        networkCondition: NetworkCondition = .unknown,
        networkConditionReason: NetworkConditionReason = .none
    ) {
        self.connectionEstimatedBandwidth = connectionEstimatedBandwidth
        self.networkCondition = networkCondition
        self.networkConditionReason = networkConditionReason
    }
}
