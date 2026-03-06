//
//  Created by Vonage on 02/03/2026.
//

import OpenTok
import VERADomain

/// Extension that bridges VERADomain's ``VideoFrameRate`` to OpenTok SDK types.
///
/// This extension provides the final conversion step from domain layer to the Vonage Video SDK,
/// mapping ``VideoFrameRate`` values to `OTCameraCaptureFrameRate` enum values.
extension VideoFrameRate {
    /// Converts to OpenTok's `OTCameraCaptureFrameRate`.
    ///
    /// This computed property provides the OpenTok SDK representation of the video frame rate.
    /// Since both enums share identical raw values, the conversion is done via raw value mapping:
    /// - `.rate1FPS` (1) → `OTCameraCaptureFrameRate.rate1FPS`
    /// - `.rate7FPS` (7) → `OTCameraCaptureFrameRate.rate7FPS`
    /// - `.rate15FPS` (15) → `OTCameraCaptureFrameRate.rate15FPS`
    /// - `.rate30FPS` (30) → `OTCameraCaptureFrameRate.rate30FPS`
    ///
    /// Falls back to `.rate30FPS` if the raw value doesn't match (defensive programming),
    /// though this should never occur in practice.
    ///
    /// This is used by ``VonagePublisherFactory`` when configuring the publisher's
    /// camera capture settings.
    ///
    /// - Returns: The corresponding OpenTok camera capture frame rate.
    public var otFrameRate: OTCameraCaptureFrameRate {
        .init(rawValue: rawValue) ?? .rate30FPS
    }
}
