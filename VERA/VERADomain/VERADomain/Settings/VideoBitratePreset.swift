//
//  Created by Vonage on 01/03/2026.
//

/// Predefined video bitrate strategies for publisher configuration.
///
/// Maps to OpenTok's `OTVideoBitratePreset` in VERAVonage and is derived from
/// VERASettings' ``SettingsVideoBitratePreset``. This domain-layer type keeps VERADomain
/// independent from both UI and SDK concerns.
///
/// Raw values match both ``SettingsVideoBitratePreset`` and `OTVideoBitratePreset` for seamless bridging:
/// - `default` (0): SDK-managed adaptive bitrate
/// - `bwSaver` (1): Moderate bandwidth saving
/// - `extraBwSaver` (2): Aggressive bandwidth saving
/// - `customBitrate` (3): User-defined maximum bitrate
///
/// - SeeAlso: ``PublisherAdvancedSettings``
public enum VideoBitratePreset: Int {
    /// Default adaptive bitrate - the SDK optimizes quality automatically.
    case `default` = 0
    
    /// Moderate bandwidth saving while keeping reasonable quality.
    case bwSaver = 1
    
    /// Aggressive bandwidth saving - minimizes data usage.
    case extraBwSaver = 2
    
    /// User-defined maximum video bitrate.
    case customBitrate = 3
}
