//
//  Created by Vonage on 26/03/2026.
//

import OpenTok
import VERADomain

/// Extension that bridges VERADomain's ``DegradationPreference`` to OpenTok SDK types.
///
/// This extension provides the final conversion step from domain layer to the Vonage Video SDK,
/// mapping ``DegradationPreference`` values to `OTDegradationPreference` enum values.
extension DegradationPreference {
    /// Converts to OpenTok's `OTDegradationPreference`.
    ///
    /// This computed property provides the OpenTok SDK representation of the degradation preference.
    /// Since both enums share identical raw values, the conversion is done via raw value mapping:
    /// - `.notSet` (-1) → `OTDegradationPreference.notSet`
    /// - `.maintainFrameRateAndResolution` (0) → `OTDegradationPreference.maintainFrameRateAndResolution`
    /// - `.maintainFrameRate` (1) → `OTDegradationPreference.maintainFrameRate`
    /// - `.maintainResolution` (2) → `OTDegradationPreference.maintainResolution`
    /// - `.balanced` (3) → `OTDegradationPreference.balanced`
    ///
    /// Falls back to `.notSet` if the raw value doesn't match (defensive programming),
    /// though this should never occur in practice.
    ///
    /// This is used by ``VonagePublisherFactory`` when configuring the publisher's
    /// degradation preference settings.
    ///
    /// - Returns: The corresponding OpenTok degradation preference.
    public var otDegradationPreference: OTDegradationPreference {
        .init(rawValue: rawValue) ?? .notSet
    }
}
