//
//  Created by Vonage on 21/02/26.
//

import Foundation

/// The video capture resolution used by the publisher.
///
/// Maps to `OTCameraCaptureResolution` in the Vonage Video SDK and VERADomain's ``VideoResolution``.
///
/// Conforms to `Codable` for `UserDefaults` persistence (encoded as its raw `Int` value)
/// and `Equatable` for comparison in tests and SwiftUI diffing. The raw value matches
/// both ``VideoResolution`` and the Vonage SDK's enum values for seamless bridging.
///
/// ## Domain Mapping
///
/// This Settings module type is converted to VERADomain's ``VideoResolution`` via the
/// ``vonageResolution`` computed property defined in `PublisherSettingsPreferences+Bridge`.
/// Since both enums share identical raw values, the conversion is direct and type-safe:
/// - `.low` (0) → `VideoResolution.low` (0) — 352x288
/// - `.medium` (1) → `VideoResolution.mediun` (1) — 640x480
/// - `.high` (2) → `VideoResolution.high` (2) — 1280x720
/// - `.high1080p` (3) → `VideoResolution.high1080p` (3) — 1920x1080
///
/// This bridging pattern ensures VERADomain remains independent from VERASettings.
///
/// ## Persistence
///
/// When saved to `UserDefaults` as part of ``PublisherSettingsPreferences``, the resolution
/// is stored as its integer raw value (0, 1, 2, or 3). This ensures backward compatibility
/// and efficient storage.
///
/// - SeeAlso: ``VideoResolution``
public enum SettingsVideoResolution: Int, CaseIterable, Codable, Equatable, Identifiable {
    /// Low resolution (352x288). Maps to `VideoResolution.low`.
    case low = 0
    
    /// Medium resolution (640x480). Maps to `VideoResolution.mediun`.
    case medium = 1
    
    /// High resolution (1280x720). Maps to `VideoResolution.high`.
    case high = 2
    
    /// High 1080p resolution (1920x1080). Maps to `VideoResolution.high1080p`.
    case high1080p = 3

    /// Unique identifier for the resolution, using the raw value.
    ///
    /// Conforms to `Identifiable` for use in SwiftUI lists and ForEach loops.
    public var id: Int { rawValue }
}

// MARK: - Display

public extension SettingsVideoResolution {
    /// Human-readable label shown in the Settings UI.
    ///
    /// Combines a localized quality label (Low/Medium/High) with the pixel dimensions.
    ///
    /// - Returns: A formatted string like "Low (352x288)" or "High (1920x1080)".
     var displayName: String {
        let displayName =
            switch self {
            case .low: "Low"
            case .medium: "Medium"
            case .high, .high1080p: "High"
            }
        return "\(displayName.localized) (\(dimensionString))"
    }

    /// The dimension string expected by ``VonagePublisherFactory`` for mapping
    /// to `OTCameraCaptureResolution`.
    ///
    /// - Returns: The resolution dimensions in "WIDTHxHEIGHT" format.
    private var dimensionString: String {
        return switch self {
        case .low: "352x288"
        case .medium: "640x480"
        case .high: "1280x720"
        case .high1080p: "1920x1080"
        }
    }
}
