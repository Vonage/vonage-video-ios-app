//
//  Created by Vonage on 21/02/26.
//

import Foundation

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

    /// The maximum audio bitrate in bits per second.
    public var maxAudioBitrate: Int32

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

    /// The default settings preferences.
    /// The default settings preferences.
    public static let `default` = PublisherSettingsPreferences()

    /// Creates a new publisher settings preferences instance.
    ///
    /// - Parameters:
    ///   - videoResolution: The video resolution. Defaults to `.medium`.
    ///   - videoFrameRate: The video frame rate. Defaults to `.fps30`.
    ///   - codecPreference: The codec preference. Defaults to `.automatic`.
    ///   - maxAudioBitrate: The maximum audio bitrate in bps. Defaults to 40,000.
    ///   - videoBitratePreset: The video bitrate preset. Defaults to `.default`.
    ///   - maxVideoBitrate: The maximum video bitrate in bps. Defaults to 500,000.
    ///   - publisherAudioFallbackEnabled: Publisher audio fallback flag. Defaults to `true`.
    ///   - subscriberAudioFallbackEnabled: Subscriber audio fallback flag. Defaults to `true`.
    ///   - senderStatsEnabled: Whether to show sender stats. Defaults to `false`.
    public init(
        videoResolution: SettingsVideoResolution = .medium,
        videoFrameRate: SettingsVideoFrameRate = .fps30,
        codecPreference: SettingsCodecPreference = .automatic,
        maxAudioBitrate: Int32 = 40_000,
        videoBitratePreset: SettingsVideoBitratePreset = .default,
        maxVideoBitrate: Int32 = 500_000,
        publisherAudioFallbackEnabled: Bool = true,
        subscriberAudioFallbackEnabled: Bool = true,
        senderStatsEnabled: Bool = false
    ) {
        self.videoResolution = videoResolution
        self.videoFrameRate = videoFrameRate
        self.codecPreference = codecPreference
        self.maxAudioBitrate = maxAudioBitrate
        self.videoBitratePreset = videoBitratePreset
        self.maxVideoBitrate = maxVideoBitrate
        self.publisherAudioFallbackEnabled = publisherAudioFallbackEnabled
        self.subscriberAudioFallbackEnabled = subscriberAudioFallbackEnabled
        self.senderStatsEnabled = senderStatsEnabled
    }

    // MARK: - Migration

    /// Custom decoder that falls back gracefully when the persisted data
    /// still uses the old `preferredVideoCodec: VideoCodec` field.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoResolution = try container.decode(SettingsVideoResolution.self, forKey: .videoResolution)
        videoFrameRate = try container.decode(SettingsVideoFrameRate.self, forKey: .videoFrameRate)
        maxAudioBitrate = try container.decode(Int32.self, forKey: .maxAudioBitrate)
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
        senderStatsEnabled = try container.decode(Bool.self, forKey: .senderStatsEnabled)

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
        case maxAudioBitrate
        case videoBitratePreset
        case maxVideoBitrate
        case publisherAudioFallbackEnabled
        case subscriberAudioFallbackEnabled
        case senderStatsEnabled
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
        try container.encode(maxAudioBitrate, forKey: .maxAudioBitrate)
        try container.encode(videoBitratePreset, forKey: .videoBitratePreset)
        try container.encode(maxVideoBitrate, forKey: .maxVideoBitrate)
        try container.encode(publisherAudioFallbackEnabled, forKey: .publisherAudioFallbackEnabled)
        try container.encode(subscriberAudioFallbackEnabled, forKey: .subscriberAudioFallbackEnabled)
        try container.encode(senderStatsEnabled, forKey: .senderStatsEnabled)
    }

    public static func == (lhs: PublisherSettingsPreferences, rhs: PublisherSettingsPreferences) -> Bool {
        lhs.videoResolution == rhs.videoResolution && lhs.videoFrameRate == rhs.videoFrameRate
            && lhs.codecPreference == rhs.codecPreference && lhs.maxAudioBitrate == rhs.maxAudioBitrate
            && lhs.videoBitratePreset == rhs.videoBitratePreset && lhs.maxVideoBitrate == rhs.maxVideoBitrate
            && lhs.publisherAudioFallbackEnabled == rhs.publisherAudioFallbackEnabled
            && lhs.subscriberAudioFallbackEnabled == rhs.subscriberAudioFallbackEnabled
    }
}
