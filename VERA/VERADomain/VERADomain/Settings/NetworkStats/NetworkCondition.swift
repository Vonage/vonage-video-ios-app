//
//  Created by Vonage on 21/05/2026.
//

/// High-level network condition score for a publisher or subscriber connection.
///
/// Maps to `OTNetworkCondition` from the Vonage Video SDK.
public enum NetworkCondition: String, Equatable, Sendable {
    case unknown
    case critical
    case warning
    case fair
    case good
    case excellent
}
