//
//  Created by Vonage on 10/5/26.
//

import Foundation

/// The engine that runs the person/background segmentation for background effects.
///
/// The Settings module's `SettingsBackgroundProvider` maps to this type at the wiring
/// layer (`VERAApp`), so that VERABackgroundEffects has no dependency on VERASettings.
/// Raw values match `SettingsBackgroundProvider` so the mapping is direct.
public enum BackgroundEffectProvider: Int, CaseIterable, Equatable {
    /// Vonage Media Library segmentation — invoked via `OTVideoTransformer(name:properties:)`.
    case vonage = 1

    /// Apple Vision person segmentation — wrapped as an `OTCustomVideoTransformer`.
    case appleVision = 2
}

/// Quality level for the Apple Vision person-segmentation request.
///
/// Maps directly to `VNGeneratePersonSegmentationRequest.QualityLevel`.
/// The Settings module's `SettingsAppleVisionQuality` shares raw values for direct mapping.
public enum AppleVisionSegmentationQuality: Int, CaseIterable, Equatable {
    /// Fastest segmentation — lowest latency, lowest accuracy. Default.
    case fast = 0

    /// Balanced segmentation — moderate latency and accuracy.
    case balanced = 1

    /// Most accurate segmentation — higher latency, suited to ANE-capable devices.
    case accurate = 2
}
