//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Predefined video-bitrate strategies that map to the Vonage SDK's
/// `OTVideoBitratePreset` enum and VERADomain's ``VideoBitratePreset``.
///
/// The first three cases correspond to preset bandwidth policies managed by the
/// SDK encoder, while ``custom`` lets the user specify an explicit maximum
/// bitrate via `maxVideoBitrate`.
///
/// Conforms to `Codable` for `UserDefaults` persistence (encoded as its raw `Int` value)
/// and `Equatable` for comparison in tests and SwiftUI diffing. The raw value matches
/// both ``VideoBitratePreset`` and the Vonage SDK's enum values for seamless bridging.
///
/// ## Domain Mapping
///
/// This Settings module type is converted to VERADomain's ``VideoBitratePreset`` via the
/// ``vonageBitratePreset`` computed property defined in `PublisherSettingsPreferences+Bridge`.
/// Since both enums share identical raw values, the conversion is direct and type-safe:
/// - `.default` (0) → `VideoBitratePreset.default` (0)
/// - `.bandwidthSaver` (1) → `VideoBitratePreset.bwSaver` (1)
/// - `.extraBandwidthSaver` (2) → `VideoBitratePreset.extraBwSaver` (2)
/// - `.custom` (3) → `VideoBitratePreset.customBitrate` (3)
///
/// This bridging pattern ensures VERADomain remains independent from VERASettings.
///
/// ## Persistence
///
/// When saved to `UserDefaults` as part of ``PublisherSettingsPreferences``, the preset
/// is stored as its integer raw value (0, 1, 2, or 3). This ensures backward compatibility
/// and efficient storage.
///
/// - SeeAlso: ``VideoBitratePreset``
public enum SettingsVideoBitratePreset: Int, Codable, Equatable, Identifiable, CaseIterable {

    /// Default adaptive behaviour — no explicit limit (SDK value `0`).
    /// Maps to `VideoBitratePreset.default`.
    case `default` = 0

    /// Moderate bandwidth saving while keeping reasonable quality.
    /// Maps to `VideoBitratePreset.bwSaver`.
    case bandwidthSaver = 1

    /// Aggressive bandwidth saving — minimises data usage.
    /// Maps to `VideoBitratePreset.extraBwSaver`.
    case extraBandwidthSaver = 2

    /// User-defined maximum video bitrate (5 000 – 10 000 000 bps).
    /// Maps to `VideoBitratePreset.customBitrate`.
    case custom = 3

    // MARK: - Identifiable

    public var id: String { rawValue.description }
}

// MARK: - Display

public extension SettingsVideoBitratePreset {
    /// Human-readable label shown in the Settings UI.
     var displayName: String {
        return switch self {
        case .default: "Default".localized
        case .bandwidthSaver: "Bandwidth Saver".localized
        case .extraBandwidthSaver: "Extra Bandwidth Saver".localized
        case .custom: "Custom".localized
        }
    }

    /// Footer text that changes based on the selected preset.
    var footerDescription: String {
        return switch self {
        case .default:
            "Default adaptive bitrate — the SDK optimises quality automatically.".localized
        case .bandwidthSaver:
            "Moderate bandwidth saving while keeping reasonable video quality.".localized
        case .extraBandwidthSaver:
            "Aggressive bandwidth saving — minimises data usage.".localized
        case .custom:
            "Set an explicit max video bitrate between 5 kbps and 10 Mbps.".localized
        }
    }
}
