//
//  Created by Vonage on 21/02/26.
//

import Foundation

/// The video capture frame rate used by the publisher.
///
/// Maps to `OTCameraCaptureFrameRate` in the Vonage Video SDK and VERADomain's ``VideoFrameRate``.
///
/// Conforms to `Codable` for `UserDefaults` persistence (encoded as its raw `Int` value)
/// and `Equatable` for comparison in tests and SwiftUI diffing. The raw value matches
/// both ``VideoFrameRate`` and the Vonage SDK's enum values for seamless bridging.
///
/// ## Domain Mapping
///
/// This Settings module type is converted to VERADomain's ``VideoFrameRate`` via the
/// ``vonageFrameRate`` computed property defined in `PublisherSettingsPreferences+Bridge`.
/// Since both enums share identical raw values, the conversion is direct and type-safe:
/// - `.fps1` (1) → `VideoFrameRate.rate1FPS` (1)
/// - `.fps7` (7) → `VideoFrameRate.rate7FPS` (7)
/// - `.fps15` (15) → `VideoFrameRate.rate15FPS` (15)
/// - `.fps30` (30) → `VideoFrameRate.rate30FPS` (30)
///
/// This bridging pattern ensures VERADomain remains independent from VERASettings.
///
/// ## Persistence
///
/// When saved to `UserDefaults` as part of ``PublisherSettingsPreferences``, the frame rate
/// is stored as its integer raw value (1, 7, 15, or 30). This ensures backward compatibility
/// and efficient storage.
///
/// - SeeAlso: ``VideoFrameRate``
public enum SettingsVideoFrameRate: Int, CaseIterable, Codable, Equatable, Identifiable {
    /// 1 frame per second. Maps to `VideoFrameRate.rate1FPS`.
    case fps1 = 1
    
    /// 7 frames per second. Maps to `VideoFrameRate.rate7FPS`.
    case fps7 = 7
    
    /// 15 frames per second. Maps to `VideoFrameRate.rate15FPS`.
    case fps15 = 15
    
    /// 30 frames per second. Maps to `VideoFrameRate.rate30FPS`.
    case fps30 = 30

    /// Unique identifier for the frame rate, using the raw value.
    ///
    /// Conforms to `Identifiable` for use in SwiftUI lists and ForEach loops.
    public var id: Int { rawValue }
}

// MARK: - Display

public extension SettingsVideoFrameRate {
    /// Human-readable label shown in the Settings UI.
    ///
    /// Formats the frame rate as "N FPS" where N is the raw value.
    ///
    /// - Returns: The frame rate string (e.g., "1 FPS", "7 FPS", "15 FPS", "30 FPS").
     var displayName: String { "\(rawValue) FPS" }
}
