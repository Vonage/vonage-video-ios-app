//
//  Created by Vonage on 10/5/26.
//

import Foundation
import OpenTok
import VERADomain
import VERAVonage

/// Namespace for the Apple Vision background-blur integration constants.
public enum AppleVisionBlur {
    /// Stable transformer key used by the Apple Vision blur path. Used to add and
    /// remove the transformer on `VERAPublisher.videoTransformers` and to identify
    /// it when switching between providers.
    public static let key = "AppleVisionBlur"
}

extension VERAPublisher {

    /// Applies (or removes) an Apple Vision-based background blur using the system Vision
    /// person-segmentation request.
    ///
    /// Behaviour mirrors ``setBackgroundBlur(blurLevel:)`` so the two providers are
    /// interchangeable from the call site's perspective.
    ///
    /// - Parameters:
    ///   - blurLevel: The blur level. ``BlurLevel/none`` removes any existing Vision blur.
    ///   - quality: Apple Vision quality level. Defaults to `.fast`.
    public func setAppleVisionBlur(
        blurLevel: BlurLevel,
        quality: AppleVisionSegmentationQuality = .fast
    ) throws {
        removeTransformer(AppleVisionBlur.key)
        removeTransformer(FrameCounter.key)

        if blurLevel != .none {
            TransformPerformanceTracker.shared.setProviderLabel("AV \(quality.hudLabel)")
            // VNGeneratePersonSegmentationRequest is a Core ML model under the
            // hood; on Apple Silicon devices it routes to the ANE for `.fast`
            // and `.balanced`. `.accurate` may spill onto the GPU. This label
            // is informed inference — Core ML doesn't expose actual dispatch.
            // Use Instruments → Core ML for definitive proof.
            TransformPerformanceTracker.shared.setEngineLabel("ANE")

            let radius = blurLevel.appleVisionBlurRadius
            let customTransformer = AppleVisionSegmentationTransformer(
                blurRadius: radius,
                quality: quality
            )

            guard
                let otVideoTransformer = OTVideoTransformer(
                    name: AppleVisionBlur.key,
                    transformer: customTransformer
                )
            else {
                throw BackgroundBlur.Error.videoTransformerInitializationError
            }

            let veraTransformer = VonageTransformer(
                key: AppleVisionBlur.key,
                transformer: otVideoTransformer
            )

            addVideoTransformer(veraTransformer)
        }
    }
}

extension AppleVisionSegmentationQuality {
    /// Compact label used by the performance HUD.
    var hudLabel: String {
        switch self {
        case .fast: return "fast"
        case .balanced: return "bal"
        case .accurate: return "acc"
        }
    }
}

extension BlurLevel {
    /// Maps the abstract blur level to a concrete CoreImage gaussian blur radius for
    /// the Apple Vision pipeline. Approximate parity with the Vonage Media Library
    /// blur ranges; calibrate visually once the composite pipeline is wired up.
    var appleVisionBlurRadius: Float {
        switch self {
        case .none: return 0
        case .low: return 6
        case .high: return 18
        }
    }
}
