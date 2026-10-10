//
//  Created by Vonage on 21/02/26.
//

import Foundation
import VERADomain

/// Value type representing all user-configurable publisher preferences.
///
/// This is the "output" of the Settings module — a pure data packet that is persisted
/// to `UserDefaults` and read by the publisher factory when creating a new publisher.
public struct PublisherSettingsPreferences: Codable, Equatable {
    /// The desired video resolution for the publisher stream.
    public var videoResolution: SettingsVideoResolution

    /// The desired video frame rate for the publisher stream.
    public var videoFrameRate: SettingsVideoFrameRate

    /// The codec preference configuration (automatic or manual with ordered list).
    public var codecPreference: SettingsCodecPreference

    /// The maximum audio bitrate preference.
    public var audioBitratePreference: SettingsAudioBitratePreference

    /// The video bitrate preset (default or custom).
    public var videoBitratePreset: SettingsVideoBitratePreset

    /// The maximum video bitrate in bits per second (only used when videoBitratePreset is custom).
    public var maxVideoBitrate: Int32

    /// Whether audio fallback is enabled for the publisher.
    public var publisherAudioFallbackEnabled: Bool

    /// Whether audio fallback is enabled for subscribers.
    public var subscriberAudioFallbackEnabled: Bool

    /// Whether sender statistics should be displayed for debugging purposes.
    public var senderStatsEnabled: Bool

    /// Whether the stats overlay should be visible in the meeting room.
    public var statsOverlayEnabled: Bool

    /// The degradation preference policy for adapting frame rate and resolution.
    public var degradationPreference: SettingsDegradationPreference

    /// Whether Opus DTX (Discontinuous Transmission) is enabled for audio encoding.
    public var opusDtxEnabled: Bool

    /// Saved camera choice, shared by Settings and the camera controls.
    public var cameraPosition: CameraPosition

    /// Whether the front-camera self-view is mirrored locally.
    public var selfViewMirroringEnabled: Bool

    public var advancedNoiseSuppressionEnabled: Bool
    public var cameraContentHint: VideoContentHint
    public var screenShareContentHint: VideoContentHint
    public var screenShareCodecMode: SettingsScreenShareCodecMode
    public var screenShareCodecPreference: SettingsCodecPreference
    public var screenShareFrameRate: SettingsVideoFrameRate?
    public var screenShareResolution: SettingsScreenShareResolution?
    public var screenShareBitratePreset: SettingsVideoBitratePreset?
    public var screenShareMaxVideoBitrate: Int32
    public var scalableScreenshareEnabled: Bool


    /// The default settings preferences.
    public static let `default` = PublisherSettingsPreferences()

    /// Creates a new publisher settings preferences instance.
    ///
    /// - Parameters:
    ///   - videoResolution: The video resolution. Defaults to `.high` (1280×720).
    ///   - videoFrameRate: The video frame rate. Defaults to `.fps30`.
    ///   - codecPreference: The codec preference. Defaults to `.automatic`.
    ///   - audioBitratePreference: The maximum audio bitrate preference. Defaults to `.default`.
    ///   - videoBitratePreset: The video bitrate preset. Defaults to `.default`.
    ///   - maxVideoBitrate: The maximum video bitrate in bps. Defaults to 500,000.
    ///   - publisherAudioFallbackEnabled: Publisher audio fallback flag. Defaults to `false`.
    ///   - subscriberAudioFallbackEnabled: Subscriber audio fallback flag. Defaults to `false`.
    ///   - senderStatsEnabled: Whether to show sender stats. Defaults to `false`.
    ///   - statsOverlayEnabled: Whether the overlay stats should be visible. Defaults to `false`.
    ///   - degradationPreference: Degradation preference policy. Defaults to `.notSet`.
    ///   - opusDtxEnabled: Whether Opus DTX is enabled. Defaults to `true`.
    ///   - selfViewMirroringEnabled: Front-camera preview mirroring. Defaults to `true`.
    ///   - cameraPosition: Saved camera choice. Defaults to `.front`.
    public init(
        videoResolution: SettingsVideoResolution = .high,
        videoFrameRate: SettingsVideoFrameRate = .fps30,
        codecPreference: SettingsCodecPreference = .automatic,
        audioBitratePreference: SettingsAudioBitratePreference = .default,
        videoBitratePreset: SettingsVideoBitratePreset = .default,
        maxVideoBitrate: Int32 = 500_000,
        publisherAudioFallbackEnabled: Bool = false,
        subscriberAudioFallbackEnabled: Bool = false,
        senderStatsEnabled: Bool = false,
        statsOverlayEnabled: Bool = false,
        degradationPreference: SettingsDegradationPreference = .notSet,
        opusDtxEnabled: Bool = true,
        selfViewMirroringEnabled: Bool = true,
        cameraPosition: CameraPosition = .front,
        advancedNoiseSuppressionEnabled: Bool = false,
        cameraContentHint: VideoContentHint = .automatic,
        screenShareContentHint: VideoContentHint = .detail,
        screenShareCodecMode: SettingsScreenShareCodecMode = .inherit,
        screenShareCodecPreference: SettingsCodecPreference = .defaultManual,
        screenShareFrameRate: SettingsVideoFrameRate? = nil,
        screenShareResolution: SettingsScreenShareResolution? = nil,
        screenShareBitratePreset: SettingsVideoBitratePreset? = nil,
        screenShareMaxVideoBitrate: Int32 = 500_000,
        scalableScreenshareEnabled: Bool = false
    ) {
        self.videoResolution = videoResolution
        self.videoFrameRate = videoFrameRate
        self.codecPreference = codecPreference
        self.audioBitratePreference = audioBitratePreference
        self.videoBitratePreset = videoBitratePreset
        self.maxVideoBitrate = maxVideoBitrate
        self.publisherAudioFallbackEnabled = publisherAudioFallbackEnabled
        self.subscriberAudioFallbackEnabled = subscriberAudioFallbackEnabled
        self.senderStatsEnabled = senderStatsEnabled
        self.statsOverlayEnabled = statsOverlayEnabled
        self.degradationPreference = degradationPreference
        self.opusDtxEnabled = opusDtxEnabled
        self.selfViewMirroringEnabled = selfViewMirroringEnabled
        self.cameraPosition = cameraPosition
        self.advancedNoiseSuppressionEnabled = advancedNoiseSuppressionEnabled
        self.cameraContentHint = cameraContentHint
        self.screenShareContentHint = screenShareContentHint
        self.screenShareCodecMode = screenShareCodecMode
        self.screenShareCodecPreference = screenShareCodecPreference
        self.screenShareFrameRate = screenShareFrameRate
        self.screenShareResolution = screenShareResolution
        self.screenShareBitratePreset = screenShareBitratePreset
        self.screenShareMaxVideoBitrate = screenShareMaxVideoBitrate
        self.scalableScreenshareEnabled = scalableScreenshareEnabled

    }

    // MARK: - Migration

    /// Custom decoder that falls back gracefully when the persisted data
    /// still uses the old `preferredVideoCodec: VideoCodec` field.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoResolution = try container.decode(SettingsVideoResolution.self, forKey: .videoResolution)
        videoFrameRate = try container.decode(SettingsVideoFrameRate.self, forKey: .videoFrameRate)
        if let audioBitratePreference = try container.decodeIfPresent(
            SettingsAudioBitratePreference.self,
            forKey: .audioBitratePreference
        ) {
            self.audioBitratePreference = audioBitratePreference
        } else if let legacyMaxAudioBitrate = try container.decodeIfPresent(
            Int32.self,
            forKey: .legacyMaxAudioBitrate
        ) {
            self.audioBitratePreference = .custom(legacyMaxAudioBitrate)
        } else {
            self.audioBitratePreference = .default
        }
        videoBitratePreset =
            try container.decodeIfPresent(SettingsVideoBitratePreset.self, forKey: .videoBitratePreset) ?? .default
        maxVideoBitrate = try container.decodeIfPresent(Int32.self, forKey: .maxVideoBitrate) ?? 0
        // New fields first; fall back to legacy single-toggle field.
        if let pub = try? container.decode(Bool.self, forKey: .publisherAudioFallbackEnabled) {
            publisherAudioFallbackEnabled = pub
            subscriberAudioFallbackEnabled = try container.decode(Bool.self, forKey: .subscriberAudioFallbackEnabled)
        } else {
            let legacy = try container.decode(Bool.self, forKey: .legacyAudioFallbackEnabled)
            publisherAudioFallbackEnabled = legacy
            subscriberAudioFallbackEnabled = legacy
        }
        senderStatsEnabled = try container.decodeIfPresent(Bool.self, forKey: .senderStatsEnabled) ?? false
        statsOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .statsOverlayEnabled) ?? true
        degradationPreference =
            try container.decodeIfPresent(SettingsDegradationPreference.self, forKey: .degradationPreference) ?? .notSet
        opusDtxEnabled = try container.decodeIfPresent(Bool.self, forKey: .opusDtxEnabled) ?? true
        selfViewMirroringEnabled = try container.decodeIfPresent(Bool.self, forKey: .selfViewMirroringEnabled) ?? true

        cameraPosition = try container.decodeIfPresent(CameraPosition.self, forKey: .cameraPosition) ?? .front
        advancedNoiseSuppressionEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .advancedNoiseSuppressionEnabled) ?? false
        cameraContentHint =
            try container.decodeIfPresent(VideoContentHint.self, forKey: .cameraContentHint) ?? .automatic
        screenShareContentHint =
            try container.decodeIfPresent(VideoContentHint.self, forKey: .screenShareContentHint) ?? .detail

        screenShareCodecMode =
            try container.decodeIfPresent(SettingsScreenShareCodecMode.self, forKey: .screenShareCodecMode) ?? .inherit
        screenShareCodecPreference =
            try container.decodeIfPresent(SettingsCodecPreference.self, forKey: .screenShareCodecPreference)
            ?? .defaultManual
        screenShareFrameRate = try container.decodeIfPresent(SettingsVideoFrameRate.self, forKey: .screenShareFrameRate)
        screenShareResolution = try container.decodeIfPresent(
            SettingsScreenShareResolution.self, forKey: .screenShareResolution)
        screenShareBitratePreset = try container.decodeIfPresent(
            SettingsVideoBitratePreset.self, forKey: .screenShareBitratePreset)
        screenShareMaxVideoBitrate =
            try container.decodeIfPresent(Int32.self, forKey: .screenShareMaxVideoBitrate) ?? 500_000
        scalableScreenshareEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .scalableScreenshareEnabled) ?? false

        // Try the new field first; fall back to legacy single-codec field.
        if let pref = try? container.decode(SettingsCodecPreference.self, forKey: .codecPreference) {
            codecPreference = pref
        } else if let legacy = try? container.decode(SettingsVideoCodec.self, forKey: .legacyPreferredVideoCodec) {
            codecPreference = SettingsCodecPreference(mode: .manual, orderedCodecs: [legacy])
        } else {
            codecPreference = .automatic
        }
    }

    private enum CodingKeys: String, CodingKey {
        case videoResolution
        case videoFrameRate
        case codecPreference
        case audioBitratePreference
        case videoBitratePreset
        case maxVideoBitrate
        case legacyMaxAudioBitrate = "maxAudioBitrate"
        case publisherAudioFallbackEnabled
        case subscriberAudioFallbackEnabled
        case senderStatsEnabled
        case statsOverlayEnabled
        case degradationPreference
        case opusDtxEnabled
        case selfViewMirroringEnabled
        case cameraPosition
        case advancedNoiseSuppressionEnabled
        case cameraContentHint
        case screenShareContentHint
        case screenShareCodecMode
        case screenShareCodecPreference
        case screenShareFrameRate
        case screenShareResolution
        case screenShareBitratePreset
        case screenShareMaxVideoBitrate
        case scalableScreenshareEnabled

        /// Old key kept for migration only.
        case legacyAudioFallbackEnabled = "audioFallbackEnabled"
        /// Old key kept for migration only.
        case legacyPreferredVideoCodec = "preferredVideoCodec"
    }

    /// Custom encoder that writes only the new `codecPreference` key
    /// (never the legacy `preferredVideoCodec`).
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoResolution, forKey: .videoResolution)
        try container.encode(videoFrameRate, forKey: .videoFrameRate)
        try container.encode(codecPreference, forKey: .codecPreference)
        try container.encode(audioBitratePreference, forKey: .audioBitratePreference)
        try container.encode(videoBitratePreset, forKey: .videoBitratePreset)
        try container.encode(maxVideoBitrate, forKey: .maxVideoBitrate)
        try container.encode(publisherAudioFallbackEnabled, forKey: .publisherAudioFallbackEnabled)
        try container.encode(subscriberAudioFallbackEnabled, forKey: .subscriberAudioFallbackEnabled)
        try container.encode(senderStatsEnabled, forKey: .senderStatsEnabled)
        try container.encode(statsOverlayEnabled, forKey: .statsOverlayEnabled)
        try container.encode(degradationPreference, forKey: .degradationPreference)
        try container.encode(opusDtxEnabled, forKey: .opusDtxEnabled)
        try container.encode(selfViewMirroringEnabled, forKey: .selfViewMirroringEnabled)
        try container.encode(cameraPosition, forKey: .cameraPosition)
        try container.encode(advancedNoiseSuppressionEnabled, forKey: .advancedNoiseSuppressionEnabled)
        try container.encode(cameraContentHint, forKey: .cameraContentHint)
        try container.encode(screenShareContentHint, forKey: .screenShareContentHint)
        try container.encode(screenShareCodecMode, forKey: .screenShareCodecMode)
        try container.encode(screenShareCodecPreference, forKey: .screenShareCodecPreference)
        try container.encodeIfPresent(screenShareFrameRate, forKey: .screenShareFrameRate)
        try container.encodeIfPresent(screenShareResolution, forKey: .screenShareResolution)
        try container.encodeIfPresent(screenShareBitratePreset, forKey: .screenShareBitratePreset)
        try container.encode(screenShareMaxVideoBitrate, forKey: .screenShareMaxVideoBitrate)
        try container.encode(scalableScreenshareEnabled, forKey: .scalableScreenshareEnabled)

    }

    public static func == (lhs: PublisherSettingsPreferences, rhs: PublisherSettingsPreferences) -> Bool {
        lhs.videoResolution == rhs.videoResolution && lhs.videoFrameRate == rhs.videoFrameRate
            && lhs.codecPreference == rhs.codecPreference
            && lhs.audioBitratePreference == rhs.audioBitratePreference
            && lhs.videoBitratePreset == rhs.videoBitratePreset && lhs.maxVideoBitrate == rhs.maxVideoBitrate
            && lhs.publisherAudioFallbackEnabled == rhs.publisherAudioFallbackEnabled
            && lhs.subscriberAudioFallbackEnabled == rhs.subscriberAudioFallbackEnabled
            && lhs.senderStatsEnabled == rhs.senderStatsEnabled
            && lhs.statsOverlayEnabled == rhs.statsOverlayEnabled
            && lhs.degradationPreference == rhs.degradationPreference
            && lhs.opusDtxEnabled == rhs.opusDtxEnabled
            && lhs.selfViewMirroringEnabled == rhs.selfViewMirroringEnabled
            && lhs.cameraPosition == rhs.cameraPosition
            && lhs.advancedNoiseSuppressionEnabled == rhs.advancedNoiseSuppressionEnabled
            && lhs.cameraContentHint == rhs.cameraContentHint
            && lhs.screenShareContentHint == rhs.screenShareContentHint
            && lhs.screenShareCodecMode == rhs.screenShareCodecMode
            && lhs.screenShareCodecPreference == rhs.screenShareCodecPreference
            && lhs.screenShareFrameRate == rhs.screenShareFrameRate
            && lhs.screenShareResolution == rhs.screenShareResolution
            && lhs.screenShareBitratePreset == rhs.screenShareBitratePreset
            && lhs.screenShareMaxVideoBitrate == rhs.screenShareMaxVideoBitrate
            && lhs.scalableScreenshareEnabled == rhs.scalableScreenshareEnabled

    }
}
