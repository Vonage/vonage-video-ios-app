//
//  Created by Vonage on 21/05/2026.
//

/// Primary reason impacting the network condition score.
///
/// Maps to `OTNetworkReason` from the Vonage Video SDK.
public enum NetworkConditionReason: String, Equatable, Sendable {
    case none
    case unknown
    case bandwidth
    case packetLoss
    case networkConditionChange
}
