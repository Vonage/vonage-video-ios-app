//
//  Created by Vonage on 01/03/2026.
//

/// Video capture resolution options for publisher configuration.
///
/// Maps to OpenTok's `OTCameraCaptureResolution` in VERAVonage and is derived from
/// VERASettings' ``SettingsVideoResolution``. This domain-layer type keeps VERADomain
/// independent from both UI and SDK concerns.
///
/// Raw values match ``SettingsVideoResolution`` for seamless bridging:
/// - `low` (0): 352x288 resolution
/// - `mediun` (1): 640x480 resolution (note: typo retained for compatibility)
/// - `high` (2): 1280x720 resolution (720p)
/// - `high1080p` (3): 1920x1080 resolution (1080p)
///
/// - SeeAlso: ``PublisherAdvancedSettings``
public enum VideoResolution: Int {
    /// Low resolution (352x288).
    case low = 0
    
    /// Medium resolution (640x480).
    case mediun = 1
    
    /// High resolution (1280x720).
    case high = 2
    
    /// High 1080p resolution (1920x1080).
    case high1080p = 3
}
