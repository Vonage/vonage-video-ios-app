//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Represents the user's codec preference: either automatic or a manually
/// ordered list of codecs the SDK should try in priority order.
///
/// Conforms to `Codable` for `UserDefaults` persistence and `Equatable` for
/// comparison in tests and SwiftUI diffing.
///
/// ## Domain Mapping
///
/// This Settings module type is converted to VERADomain's ``VideoCodecPreference``
/// via the ``vonageCodecPreference`` computed property defined in `PublisherSettingsPreferences+Bridge`.
/// The mapping transforms:
/// - ``mode`` → `automatic: Bool` (true if mode is `.automatic`, false if `.manual`)
/// - ``orderedCodecs`` → `codecs: [VideoCodecType]?` (each ``SettingsVideoCodec`` converted to ``VideoCodecType``)
///
/// This bridging pattern ensures VERADomain remains independent from VERASettings.
///
/// - SeeAlso: ``SettingsCodecMode``, ``SettingsVideoCodec``, ``VideoCodecPreference``
public struct SettingsCodecPreference: Codable, Equatable {

    /// The selection mode — automatic or manual.
    public var mode: SettingsCodecMode

    /// The user's preferred codec order (only meaningful when ``mode`` is `.manual`).
    ///
    /// Defaults to `[.vp9, .vp8, .h264]`. In automatic mode this array is
    /// ignored by the SDK but kept in memory so the user's ordering is
    /// preserved if they switch back to manual.
    public var orderedCodecs: [SettingsVideoCodec]

    /// Creates a new codec preference.
    ///
    /// - Parameters:
    ///   - mode: The selection mode (automatic or manual). Defaults to `.automatic`.
    ///   - orderedCodecs: The user's preferred codec order. Defaults to `[.vp9, .vp8, .h264]`.
    public init(
        mode: SettingsCodecMode = .automatic,
        orderedCodecs: [SettingsVideoCodec] = [.vp9, .vp8, .h264]
    ) {
        self.mode = mode
        self.orderedCodecs = orderedCodecs
    }
}

extension SettingsCodecPreference {
    /// Automatic preference — the SDK decides.
    public static let automatic = SettingsCodecPreference(mode: .automatic)

    /// Default manual preference: VP9 → VP8 → H.264.
    public static let defaultManual = SettingsCodecPreference(
        mode: .manual,
        orderedCodecs: [.vp9, .vp8, .h264]
    )
}

/// How the user wants the video codec to be selected.
public enum SettingsCodecMode: String, Codable, Equatable, CaseIterable, Identifiable {
    /// Let the SDK choose the best codec automatically.
    case automatic
    /// The user specifies an ordered list of preferred codecs.
    case manual

    public var id: String { rawValue }
}

// MARK: - Display

public extension SettingsCodecMode {
    /// Human-readable label shown in the Settings UI.
    var displayName: String {
        return switch self {
        case .automatic: "Automatic".localized
        case .manual: "Manual".localized
        }
    }

    /// Footer text for the codec section.
    var footerDescription: String {
        return switch self {
        case .automatic:
            "The SDK automatically selects the best codec based on network conditions and participant capabilities."
                .localized
        case .manual:
            "Drag to reorder. The SDK will try codecs in this order during negotiation.".localized
        }
    }
}
