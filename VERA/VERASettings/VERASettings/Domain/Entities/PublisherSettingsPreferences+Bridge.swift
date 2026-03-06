//
//  Created by Vonage on 21/02/26.
//

import VERADomain

/// Extensions that bridge Settings module types to VERADomain types.
///
/// These conversions ensure that VERADomain doesn't depend on VERASettings,
/// allowing the domain layer to remain independent.
extension PublisherSettingsPreferences {
    /// Converts the rich Settings enum types into the `String`/`Int`-based fields
    /// used by ``PublisherAdvancedSettings`` so that `VERADomain` does not depend on `VERASettings`.
    public func toPublisherAdvancedSettings() -> PublisherAdvancedSettings {
        PublisherAdvancedSettings(
            videoResolution: videoResolution.vonageResolution,
            videoFrameRate: videoFrameRate.vonageFrameRate,
            preferredVideoCodecs: codecPreference.vonageCodecPreference,
            maxAudioBitrate: maxAudioBitrate,
            videoBitratePreset: videoBitratePreset.vonageBitratePreset,
            maxVideoBitrate: videoBitratePreset == .custom ? maxVideoBitrate : nil,
            publisherAudioFallbackEnabled: publisherAudioFallbackEnabled,
            subscriberAudioFallbackEnabled: subscriberAudioFallbackEnabled
        )
    }
}

extension SettingsVideoResolution {
    /// Converts to ``VideoResolution`` used by VERADomain.
    ///
    /// This property bridges the Settings module's ``SettingsVideoResolution`` to the domain layer's
    /// ``VideoResolution``. Both enums share identical raw values:
    /// - `.low` (0) → `VideoResolution.low` (0)
    /// - `.medium` (1) → `VideoResolution.mediun` (1)
    /// - `.high` (2) → `VideoResolution.high` (2)
    /// - `.high1080p` (3) → `VideoResolution.high1080p` (3)
    ///
    /// Falls back to `.low` if the raw value doesn't match (defensive programming),
    /// though this should never occur in practice.
    ///
    /// - Returns: The corresponding ``VideoResolution`` from VERADomain.
    var vonageResolution: VideoResolution {
        .init(rawValue: rawValue) ?? .low
    }
}

extension SettingsVideoBitratePreset {
    /// Converts to ``VideoBitratePreset`` used by VERADomain.
    ///
    /// This property bridges the Settings module's ``SettingsVideoBitratePreset`` to the domain layer's
    /// ``VideoBitratePreset``. Both enums share identical raw values:
    /// - `.default` (0) → `VideoBitratePreset.default` (0)
    /// - `.bandwidthSaver` (1) → `VideoBitratePreset.bwSaver` (1)
    /// - `.extraBandwidthSaver` (2) → `VideoBitratePreset.extraBwSaver` (2)
    /// - `.custom` (3) → `VideoBitratePreset.customBitrate` (3)
    ///
    /// Falls back to `.default` if the raw value doesn't match (defensive programming),
    /// though this should never occur in practice.
    ///
    /// - Returns: The corresponding ``VideoBitratePreset`` from VERADomain.
    var vonageBitratePreset: VideoBitratePreset {
        .init(rawValue: rawValue) ?? .default
    }
}

extension SettingsCodecPreference {
    /// Converts to ``VideoCodecPreference`` used by VERADomain.
    ///
    /// This property bridges the Settings module's ``SettingsCodecPreference`` to the domain layer's
    /// ``VideoCodecPreference``. The transformation:
    /// - Converts ``mode`` to a boolean: `.automatic` → `true`, `.manual` → `false`
    /// - Maps each ``SettingsVideoCodec`` in ``orderedCodecs`` to ``VideoCodecType``
    ///
    /// Example:
    /// ```swift
    /// let settings = SettingsCodecPreference(mode: .manual, orderedCodecs: [.vp9, .vp8])
    /// let domain = settings.vonageCodecPreference
    /// // domain.automatic == false
    /// // domain.codecs == [.vp9, .vp8]
    /// ```
    ///
    /// - Returns: The corresponding ``VideoCodecPreference`` from VERADomain.
    var vonageCodecPreference: VideoCodecPreference {
        .init(
            automatic: mode == .automatic,
            codecs: orderedCodecs.map { $0.vonageCodec }
        )
    }
}

extension SettingsVideoCodec {
    /// Converts to ``VideoCodecType`` used by VERADomain.
    ///
    /// This property bridges the Settings module's ``SettingsVideoCodec`` to the domain layer's
    /// ``VideoCodecType``. Both enums share identical raw values:
    /// - `.vp8` (1) → `VideoCodecType.vp8` (1)
    /// - `.h264` (2) → `VideoCodecType.h264` (2)
    /// - `.vp9` (3) → `VideoCodecType.vp9` (3)
    ///
    /// Falls back to `.vp8` if the raw value doesn't match (defensive programming),
    /// though this should never occur in practice.
    ///
    /// - Returns: The corresponding ``VideoCodecType`` from VERADomain.
    var vonageCodec: VideoCodecType {
        .init(rawValue: rawValue) ?? .vp8
    }
}

extension SettingsVideoFrameRate {
    /// Converts to ``VideoFrameRate`` used by VERADomain.
    ///
    /// This property bridges the Settings module's ``SettingsVideoFrameRate`` to the domain layer's
    /// ``VideoFrameRate``. Both enums share identical raw values:
    /// - `.fps1` (1) → `VideoFrameRate.rate1FPS` (1)
    /// - `.fps7` (7) → `VideoFrameRate.rate7FPS` (7)
    /// - `.fps15` (15) → `VideoFrameRate.rate15FPS` (15)
    /// - `.fps30` (30) → `VideoFrameRate.rate30FPS` (30)
    ///
    /// Falls back to `.rate30FPS` if the raw value doesn't match (defensive programming),
    /// though this should never occur in practice.
    ///
    /// - Returns: The corresponding ``VideoFrameRate`` from VERADomain.
    var vonageFrameRate: VideoFrameRate {
        .init(rawValue: rawValue) ?? .rate30FPS
    }
}
