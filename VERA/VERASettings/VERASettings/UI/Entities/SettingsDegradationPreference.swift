//
//  Created by Vonage on 26/03/2026.
//

import Foundation

/// Describes the policy the video engine follows when adapting frame rate
/// and resolution to limited bandwidth and CPU.
///
/// Maps to VERADomain's ``DegradationPreference`` via the
/// ``vonageDegradationPreference`` computed property defined in
/// `PublisherSettingsPreferences+Bridge`. Since both enums share identical
/// raw values, the conversion is direct and type-safe:
/// - `.notSet` (-1) → `DegradationPreference.notSet` (-1)
/// - `.maintainFrameRateAndResolution` (0) → `DegradationPreference.maintainFrameRateAndResolution` (0)
/// - `.maintainFrameRate` (1) → `DegradationPreference.maintainFrameRate` (1)
/// - `.maintainResolution` (2) → `DegradationPreference.maintainResolution` (2)
/// - `.balanced` (3) → `DegradationPreference.balanced` (3)
///
/// Conforms to `Codable` for `UserDefaults` persistence (encoded as its raw `Int` value)
/// and `Equatable` for comparison in tests and SwiftUI diffing.
///
/// - SeeAlso: ``DegradationPreference``
public enum SettingsDegradationPreference: Int, Codable, Equatable, Identifiable, CaseIterable {

    /// Default value — the video engine decides the optimal degradation preference.
    /// Maps to `DegradationPreference.notSet`.
    case notSet = -1

    /// No degradation applied. The video engine will not reduce resolution and
    /// will try to keep the frame rate steady.
    /// Maps to `DegradationPreference.maintainFrameRateAndResolution`.
    case maintainFrameRateAndResolution = 0

    /// The video engine will try to keep the frame rate steady but might reduce
    /// resolution if necessary.
    /// Maps to `DegradationPreference.maintainFrameRate`.
    case maintainFrameRate = 1

    /// The video engine will not reduce the resolution but might reduce the
    /// frame rate if necessary.
    /// Maps to `DegradationPreference.maintainResolution`.
    case maintainResolution = 2

    /// The video engine will try to reach a balance between reducing resolution
    /// and frame rate when necessary.
    /// Maps to `DegradationPreference.balanced`.
    case balanced = 3

    // MARK: - Identifiable

    public var id: String { rawValue.description }
}

// MARK: - Display

extension SettingsDegradationPreference {
    /// Human-readable label shown in the Settings UI.
    public var displayName: String {
        return switch self {
        case .notSet: "Not Set".localized
        case .maintainFrameRateAndResolution: "Maintain Frame Rate and Resolution".localized
        case .maintainFrameRate: "Maintain Frame Rate".localized
        case .maintainResolution: "Maintain Resolution".localized
        case .balanced: "Balanced".localized
        }
    }

    /// Footer text that changes based on the selected degradation preference.
    public var footerDescription: String {
        return switch self {
        case .notSet:
            "The video engine will decide the optimal degradation preference.".localized
        case .maintainFrameRateAndResolution:
            "No degradation will be applied — resolution and frame rate remain steady.".localized
        case .maintainFrameRate:
            "Frame rate is prioritised — resolution may be reduced under limited resources.".localized
        case .maintainResolution:
            "Resolution is prioritised — frame rate may be reduced under limited resources.".localized
        case .balanced:
            "A balance between resolution and frame rate reduction when under limited resources.".localized
        }
    }
}
