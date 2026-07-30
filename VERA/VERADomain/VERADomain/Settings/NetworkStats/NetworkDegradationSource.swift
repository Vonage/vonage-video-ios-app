//
//  Created by Vonage on 21/05/2026.
//

/// Indicates which side of the connection is responsible for network degradation.
///
/// Maps to `OTNetworkDegradationSource` from the Vonage Video SDK.
public enum NetworkDegradationSource: String, Equatable, Sendable {
    case local
    case remote
    case bothOrUnclear
    case unknown
}
