//
//  Created by Vonage on 21/05/2026.
//

/// Reason for quality limitation on a publisher video layer.
///
/// Maps to `OTPublisherKitVideoQualityLimitationReason` from the Vonage Video SDK.
public enum QualityLimitationReason: String, Equatable, Sendable {
    case none
    case bandwidth
    case cpu
    case codec
    case resolution
    case layerChange
}
