//
//  Created by Vonage on 10/5/26.
//

import Foundation

/// Quality level for the Apple Vision person-segmentation request.
///
/// Maps directly to `VNGeneratePersonSegmentationRequest.QualityLevel`. Conforms to
/// `Codable` for `UserDefaults` persistence (encoded as its raw `Int`).
///
/// ## Cases
///
/// - **Fast** (raw value: 0): Lowest latency, lowest accuracy. Default — preserves the
///   experience on older iPhones and battery-constrained scenarios.
/// - **Balanced** (raw value: 1): Tradeoff between latency and accuracy.
/// - **Accurate** (raw value: 2): Highest accuracy; suitable for Apple Silicon Macs with
///   a more capable ANE, at the cost of latency.
///
/// ## Domain Mapping
///
/// Mapped to ``AppleVisionSegmentationQuality`` in VERABackgroundEffects at the wiring
/// layer. The raw values match so the mapping is direct.
public enum SettingsAppleVisionQuality: Int, CaseIterable, Codable, Equatable, Identifiable {
    /// Fastest segmentation — default.
    case fast = 0

    /// Balanced segmentation.
    case balanced = 1

    /// Most accurate segmentation.
    case accurate = 2

    /// Unique identifier for the quality, using the raw value.
    public var id: Int { rawValue }
}

// MARK: - Display

extension SettingsAppleVisionQuality {
    /// Human-readable label shown in the Settings UI.
    public var displayName: String {
        return switch self {
        case .fast: "Fast"
        case .balanced: "Balanced"
        case .accurate: "Accurate"
        }
    }
}
