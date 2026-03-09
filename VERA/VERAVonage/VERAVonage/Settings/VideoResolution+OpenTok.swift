//
//  Created by Vonage on 02/03/2026.
//

import OpenTok
import VERADomain

/// Extension that bridges VERADomain's ``VideoResolution`` to OpenTok SDK types.
///
/// This extension provides the final conversion step from domain layer to the Vonage Video SDK,
/// mapping ``VideoResolution`` values to `OTCameraCaptureResolution` enum values.
extension VideoResolution {
    /// Converts to OpenTok's `OTCameraCaptureResolution`.
    ///
    /// This computed property provides the OpenTok SDK representation of the video resolution.
    /// The mapping is:
    /// - `.low` → `OTCameraCaptureResolution.low` (352x288)
    /// - `.mediun` → `OTCameraCaptureResolution.medium` (640x480)
    /// - `.high` → `OTCameraCaptureResolution.high` (1280x720)
    /// - `.high1080p` → `OTCameraCaptureResolution.high1080p` (1920x1080)
    ///
    /// This is used by ``VonagePublisherFactory`` when configuring the publisher's
    /// camera capture settings.
    ///
    /// - Returns: The corresponding OpenTok camera capture resolution.
    public var otResolution: OTCameraCaptureResolution {
        switch self {
        case .low:
            return .low
        case .mediun:
            return .medium
        case .high:
            return .high
        case .high1080p:
            return .high1080p
        }
    }
}
