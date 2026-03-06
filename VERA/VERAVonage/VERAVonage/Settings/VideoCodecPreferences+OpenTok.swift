//
//  Created by Vonage on 02/03/2026.
//

import OpenTok
import VERADomain

/// Extension that bridges VERADomain's ``VideoCodecPreference`` to OpenTok SDK types.
///
/// This extension provides the final conversion step from domain layer to the Vonage Video SDK,
/// mapping ``VideoCodecPreference`` values to `OTVideoCodecPreference` objects.
extension VideoCodecPreference {
    /// Converts to OpenTok's `OTVideoCodecPreference`.
    ///
    /// This computed property provides the OpenTok SDK representation of codec preferences.
    /// The conversion logic:
    /// - If `automatic` is `true` (or `codecs` is `nil`): Returns `OTVideoCodecPreference.automatic()`
    /// - If `automatic` is `false` with a codec list: Returns `OTVideoCodecPreference.manual(withCodecs:)`
    ///   with the ordered list of ``VideoCodecType`` values converted to `OTVideoCodecType` raw values.
    ///
    /// Example:
    /// ```swift
    /// let preference = VideoCodecPreference(automatic: false, codecs: [.vp9, .vp8, .h264])
    /// let otPreference = preference.otCodecPreference
    /// // Creates manual preference with order: VP9 → VP8 → H.264
    /// ```
    ///
    /// This is used by ``VonagePublisherFactory`` when configuring the publisher's
    /// codec negotiation strategy.
    ///
    /// - Returns: The corresponding OpenTok video codec preference, or `nil` if conversion fails.
    public var otCodecPreference: OTVideoCodecPreference? {
        guard let codecs else { return OTVideoCodecPreference.automatic() }

        let otCodecs = codecs.map { $0.otVideoCodecType.rawValue }.map(NSNumber.init)

        return OTVideoCodecPreference.manual(withCodecs: otCodecs)
    }
}
