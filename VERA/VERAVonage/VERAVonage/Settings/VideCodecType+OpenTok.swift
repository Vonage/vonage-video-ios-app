//
//  Created by Vonage on 02/03/2026.
//

import OpenTok
import VERADomain

/// Extension that bridges VERADomain's ``VideoCodecType`` to OpenTok SDK types.
///
/// This extension provides the final conversion step from domain layer to the Vonage Video SDK,
/// mapping ``VideoCodecType`` values to `OTVideoCodecType` enum values.
extension VideoCodecType {
    /// Converts to OpenTok's `OTVideoCodecType`.
    ///
    /// This computed property provides the OpenTok SDK representation of the video codec.
    /// Since both enums share identical raw values, the conversion is done via raw value mapping:
    /// - `.vp8` (1) → `OTVideoCodecType.VP8`
    /// - `.h264` (2) → `OTVideoCodecType.H264`
    /// - `.vp9` (3) → `OTVideoCodecType.VP9`
    ///
    /// Falls back to `.VP8` if the raw value doesn't match (defensive programming),
    /// though this should never occur in practice.
    ///
    /// This is used when constructing codec preferences for the publisher.
    ///
    /// - Returns: The corresponding OpenTok video codec type.
    public var otVideoCodecType: OTVideoCodecType {
        .init(rawValue: rawValue) ?? .VP8
    }
}
