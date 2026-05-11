//
//  Created by Vonage on 25/1/26.
//

import Foundation
import OpenTok
import VERADomain
import VERAVonage

extension VERAPublisher {

    /// Applies (or removes) a background blur via the selected provider.
    ///
    /// - When ``provider`` is `.vonage`, uses the Vonage Media Library blur transformer
    ///   (the legacy default — unchanged from the original implementation).
    /// - When ``provider`` is `.appleVision`, uses the on-device
    ///   `VNGeneratePersonSegmentationRequest` wrapped as an `OTCustomVideoTransformer`.
    ///
    /// Selecting one provider clears any transformer added by the other, so the two
    /// providers are mutually exclusive and the call site does not need to know which
    /// provider is currently active.
    ///
    /// - Parameters:
    ///   - blurLevel: Blur level. ``BlurLevel/none`` removes any active blur transformer.
    ///   - provider: Segmentation engine. Defaults to `.vonage` to preserve existing
    ///     behaviour for call sites that haven't migrated to provider awareness.
    ///   - appleVisionQuality: Apple Vision quality. Only consulted when
    ///     `provider == .appleVision`. Defaults to `.fast`.
    public func setBackgroundBlur(
        blurLevel: BlurLevel,
        provider: BackgroundEffectProvider = .vonage,
        appleVisionQuality: AppleVisionSegmentationQuality = .fast
    ) throws {
        // Clear whichever provider's transformer is currently active so switching
        // mid-effect doesn't leave stale transformers attached.
        removeTransformer(BackgroundBlur.key)
        removeTransformer(AppleVisionBlur.key)
        removeTransformer(FrameCounter.key)
        TransformPerformanceTracker.shared.reset()

        guard blurLevel != .none else {
            TransformPerformanceTracker.shared.setProviderLabel("off")
            TransformPerformanceTracker.shared.setEngineLabel("—")
            return
        }

        switch provider {
        case .vonage:
            TransformPerformanceTracker.shared.setProviderLabel("Vonage")
            // Vonage's bundled blur runs through TFLite XNNPACK on CPU lanes
            // (visible at framework load: "Created TensorFlow Lite XNNPACK
            // delegate for CPU"). It doesn't route to the ANE.
            TransformPerformanceTracker.shared.setEngineLabel("CPU")
            let params = try BackgroundBlur().params(blurLevel: blurLevel)
            let vonageTransformer = try transformerFactory.makeVideoTransformer(
                for: BackgroundBlur.key,
                params: params
            )
            addVideoTransformer(vonageTransformer)

            // Chain a passthrough counter so the HUD can report FPS + resolution
            // for the Vonage path (their transformer is opaque to us). Only attach
            // when the HUD is enabled so HUD-off operation doesn't pay for extra
            // per-frame overhead.
            if TransformPerformanceTracker.shared.isVisible,
                let counterOT = OTVideoTransformer(
                    name: FrameCounter.key, transformer: FrameCounterTransformer())
            {
                addVideoTransformer(
                    VonageTransformer(key: FrameCounter.key, transformer: counterOT))
            }

        case .appleVision:
            try setAppleVisionBlur(blurLevel: blurLevel, quality: appleVisionQuality)
        }
    }
}
