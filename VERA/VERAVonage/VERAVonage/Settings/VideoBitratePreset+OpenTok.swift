//
//  Created by Vonage on 01/03/2026.
//

import OpenTok
import VERADomain

/// Extension that bridges VERADomain's ``VideoBitratePreset`` to OpenTok SDK types.
///
/// This extension provides the final conversion step from domain layer to the Vonage Video SDK,
/// mapping ``VideoBitratePreset`` values to `OTVideoBitratePreset` enum values.
extension VideoBitratePreset {
    /// Converts to OpenTok's `OTVideoBitratePreset`.
    ///
    /// This computed property provides the OpenTok SDK representation of the video bitrate preset.
    /// Since both enums share identical raw values, the conversion is done via raw value mapping:
    /// - `.default` (0) → `OTVideoBitratePreset.default`
    /// - `.bwSaver` (1) → `OTVideoBitratePreset` bandwidth saver
    /// - `.extraBwSaver` (2) → `OTVideoBitratePreset` extra bandwidth saver
    /// - `.customBitrate` (3) → `OTVideoBitratePreset` custom
    ///
    /// Falls back to `.default` if the raw value doesn't match (defensive programming),
    /// though this should never occur in practice.
    ///
    /// This is used by ``VonagePublisherFactory`` when configuring the publisher's
    /// video bitrate settings.
    ///
    /// - Returns: The corresponding OpenTok video bitrate preset.
    public var otBitratePreset: OTVideoBitratePreset {
        .init(rawValue: rawValue) ?? .default
    }
}
