//
//  Created by Vonage on 01/03/2026.
//

/// Represents video codec types used for publisher configuration.
///
/// Maps to OpenTok's `OTVideoCodecType` in VERAVonage and is derived from
/// VERASettings' ``SettingsVideoCodec``. This domain-layer type keeps VERADomain
/// independent from both UI and SDK concerns.
///
/// Raw values match both ``SettingsVideoCodec`` and `OTVideoCodecType` for seamless bridging:
/// - `vp8` (1): Google's widely-supported open video codec
/// - `h264` (2): Industry-standard codec with excellent hardware support
/// - `vp9` (3): Google's next-generation codec with improved compression
///
/// - SeeAlso: ``VideoCodecPreference``, ``PublisherAdvancedSettings``
public enum VideoCodecType: Int, Equatable {
    /// VP8 codec - Google's widely-supported open video codec.
    case vp8 = 1
    
    /// H.264 codec - Industry-standard with excellent hardware support.
    case h264 = 2
    
    /// VP9 codec - Google's next-generation codec with improved compression.
    case vp9 = 3
}
