//
//  Created by Vonage on 10/5/26.
//

import Foundation

/// The engine that produces the person/background mask for background effects.
///
/// Maps to a ``BackgroundEffectProvider`` value consumed by ``VERABackgroundEffects``.
/// Conforms to `Codable` for `UserDefaults` persistence (encoded as its raw `Int`),
/// matching the same persistence pattern as ``SettingsVideoCodec`` and friends.
///
/// ## Cases
///
/// - **Vonage** (raw value: 1): The existing Vonage Media Library segmentation pipeline.
/// - **Apple Vision** (raw value: 2): On-device `VNGeneratePersonSegmentationRequest`. Uses
///   the Apple Neural Engine where available.
///
/// ## Domain Mapping
///
/// Mapped to VERABackgroundEffects' provider enum at the wiring layer. VERASettings does
/// not depend on VERABackgroundEffects, so the mapping happens in the dependency container.
public enum SettingsBackgroundProvider: Int, CaseIterable, Codable, Equatable, Identifiable {
    /// Vonage Media Library segmentation — the existing default.
    case vonage = 1

    /// Apple Vision person segmentation — on-device, ANE-accelerated where available.
    case appleVision = 2

    /// Unique identifier for the provider, using the raw value.
    public var id: Int { rawValue }
}

// MARK: - Display

extension SettingsBackgroundProvider {
    /// Human-readable label shown in the Settings UI.
    public var displayName: String {
        return switch self {
        case .vonage: "Vonage"
        case .appleVision: "Apple Vision"
        }
    }
}
