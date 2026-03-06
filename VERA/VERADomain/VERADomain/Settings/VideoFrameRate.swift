//
//  Created by Vonage on 01/03/2026.
//

/// Video capture frame rate options for publisher configuration.
///
/// Maps to OpenTok's `OTCameraCaptureFrameRate` in VERAVonage and is derived from
/// VERASettings' ``SettingsVideoFrameRate``. This domain-layer type keeps VERADomain
/// independent from both UI and SDK concerns.
///
/// Raw values match both ``SettingsVideoFrameRate`` and `OTCameraCaptureFrameRate` for seamless bridging.
/// The values represent frames per second.
///
/// - SeeAlso: ``PublisherAdvancedSettings``
public enum VideoFrameRate: Int {
    /// 30 frames per second - standard video quality.
    case rate30FPS = 30

    /// 15 frames per second - moderate bandwidth saving.
    case rate15FPS = 15

    /// 7 frames per second - lower bandwidth usage.
    case rate7FPS = 7

    /// 1 frame per second - minimal bandwidth usage.
    case rate1FPS = 1
}
