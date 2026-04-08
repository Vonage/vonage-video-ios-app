//
//  Created by Vonage on 26/03/2026.
//

/// Describes the policy the video engine follows when adapting frame rate
/// and resolution to limited bandwidth and CPU.
///
/// Maps to the Vonage SDK's degradation preference enum in VERAVonage and is derived from
/// VERASettings' ``SettingsDegradationPreference``. This domain-layer type keeps VERADomain
/// independent from both UI and SDK concerns.
///
/// Raw values match both ``SettingsDegradationPreference`` and the SDK enum for seamless bridging:
/// - `notSet` (-1): SDK chooses the optimal strategy
/// - `maintainFrameRateAndResolution` (0): No degradation applied
/// - `maintainFrameRate` (1): Keep frame rate, may reduce resolution
/// - `maintainResolution` (2): Keep resolution, may reduce frame rate
/// - `balanced` (3): Balance between resolution and frame rate reduction
///
/// - SeeAlso: ``PublisherAdvancedSettings``
public enum DegradationPreference: Int {
    /// Default value — the video engine decides the optimal degradation preference.
    case notSet = -1

    /// No degradation applied. The video engine will not reduce resolution and will try
    /// to keep the frame rate steady.
    case maintainFrameRateAndResolution = 0

    /// The video engine will try to keep the frame rate steady but might reduce
    /// resolution if necessary.
    case maintainFrameRate = 1

    /// The video engine will not reduce the resolution but might reduce the frame rate
    /// if necessary.
    case maintainResolution = 2

    /// The video engine will try to reach a balance between reducing resolution and
    /// frame rate when necessary.
    case balanced = 3
}
