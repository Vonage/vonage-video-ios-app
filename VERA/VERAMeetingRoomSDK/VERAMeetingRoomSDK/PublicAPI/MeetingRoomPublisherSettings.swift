//
//  Created by Vonage on 28/5/26.
//

import Foundation

// MARK: - Video Scale Behavior

/// Defines how video should be scaled when displayed in a view.
public enum MeetingRoomVideoScaleBehavior: String, Equatable, Sendable {
    /// Fill the entire view, potentially cropping video to maintain aspect ratio.
    case fill
    /// Fit the video within the view, maintaining aspect ratio with letterboxing/pillarboxing.
    case fit
}

// MARK: - Noise Suppression State

/// The high-level state of the Noise Suppression feature.
public enum MeetingRoomNoiseSuppressionState: Equatable, Sendable {
    case enabled
    case disabled
    case idle
}

// MARK: - Video Effect

/// The video effect applied to the publisher's stream.
public enum MeetingRoomVideoEffect: Equatable, Hashable, Sendable {
    /// No effect — raw camera feed is published.
    case none
    /// Low-intensity background blur.
    case blurLow
    /// High-intensity background blur.
    case blurHigh
    /// Virtual background replacement with the image at the given file-system path.
    case backgroundImage(id: String, imagePath: String)
}

// MARK: - Video Resolution

/// Video capture resolution options for publisher configuration.
public enum MeetingRoomVideoResolution: Int, Sendable {
    /// Low resolution (352x288).
    case low = 0
    /// Medium resolution (640x480).
    case medium = 1
    /// High resolution (1280x720).
    case high = 2
    /// High 1080p resolution (1920x1080).
    case high1080p = 3
}

// MARK: - Video Frame Rate

/// Video capture frame rate options for publisher configuration.
public enum MeetingRoomVideoFrameRate: Int, Sendable {
    /// 30 frames per second.
    case rate30FPS = 30
    /// 15 frames per second.
    case rate15FPS = 15
    /// 7 frames per second.
    case rate7FPS = 7
    /// 1 frame per second.
    case rate1FPS = 1
}

// MARK: - Video Codec Type

/// Video codec types used for publisher configuration.
public enum MeetingRoomVideoCodecType: Int, Equatable, Sendable {
    /// VP8 codec.
    case vp8 = 1
    /// H.264 codec.
    case h264 = 2
    /// VP9 codec.
    case vp9 = 3
}

// MARK: - Video Codec Preference

/// Codec selection preferences for video publishing.
public struct MeetingRoomVideoCodecPreference: Equatable, Hashable, Sendable {
    /// Whether codec selection should be automatic.
    public let automatic: Bool
    /// The ordered list of preferred codecs (only meaningful when `automatic` is `false`).
    public let codecs: [MeetingRoomVideoCodecType]?

    public init(automatic: Bool, codecs: [MeetingRoomVideoCodecType]? = nil) {
        self.automatic = automatic
        self.codecs = codecs
    }
}

// MARK: - Video Bitrate Preset

/// Predefined video bitrate strategies for publisher configuration.
public enum MeetingRoomVideoBitratePreset: Int, Sendable {
    /// Default adaptive bitrate.
    case `default` = 0
    /// Moderate bandwidth saving.
    case bwSaver = 1
    /// Aggressive bandwidth saving.
    case extraBwSaver = 2
    /// User-defined maximum video bitrate.
    case customBitrate = 3
}

// MARK: - Degradation Preference

/// Policy the video engine follows when adapting frame rate and resolution.
public enum MeetingRoomDegradationPreference: Int, Sendable {
    /// SDK chooses the optimal strategy.
    case notSet = -1
    /// No degradation applied.
    case maintainFrameRateAndResolution = 0
    /// Keep frame rate, may reduce resolution.
    case maintainFrameRate = 1
    /// Keep resolution, may reduce frame rate.
    case maintainResolution = 2
    /// Balance between resolution and frame rate reduction.
    case balanced = 3
}

// MARK: - Publisher Advanced Settings

/// Advanced publisher configuration settings for fine-tuning video and audio quality.
public struct MeetingRoomPublisherAdvancedSettings: Equatable, Hashable, Sendable {
    public let videoResolution: MeetingRoomVideoResolution?
    public let videoFrameRate: MeetingRoomVideoFrameRate?
    public let preferredVideoCodecs: MeetingRoomVideoCodecPreference?
    public let maxAudioBitrate: Int32?
    public let videoBitratePreset: MeetingRoomVideoBitratePreset?
    public let maxVideoBitrate: Int32?
    public let publisherAudioFallbackEnabled: Bool?
    public let subscriberAudioFallbackEnabled: Bool?
    public let degradationPreference: MeetingRoomDegradationPreference?
    public let opusDtxEnabled: Bool?

    public init(
        videoResolution: MeetingRoomVideoResolution? = nil,
        videoFrameRate: MeetingRoomVideoFrameRate? = nil,
        preferredVideoCodecs: MeetingRoomVideoCodecPreference? = nil,
        maxAudioBitrate: Int32? = nil,
        videoBitratePreset: MeetingRoomVideoBitratePreset? = nil,
        maxVideoBitrate: Int32? = nil,
        publisherAudioFallbackEnabled: Bool? = nil,
        subscriberAudioFallbackEnabled: Bool? = nil,
        degradationPreference: MeetingRoomDegradationPreference? = nil,
        opusDtxEnabled: Bool? = nil
    ) {
        self.videoResolution = videoResolution
        self.videoFrameRate = videoFrameRate
        self.preferredVideoCodecs = preferredVideoCodecs
        self.maxAudioBitrate = maxAudioBitrate
        self.videoBitratePreset = videoBitratePreset
        self.maxVideoBitrate = maxVideoBitrate
        self.publisherAudioFallbackEnabled = publisherAudioFallbackEnabled
        self.subscriberAudioFallbackEnabled = subscriberAudioFallbackEnabled
        self.degradationPreference = degradationPreference
        self.opusDtxEnabled = opusDtxEnabled
    }
}

// MARK: - Publisher Settings

/// Basic publisher configuration settings.
///
/// Contains fundamental settings for creating a video publisher, including user identity,
/// media publishing flags, display behavior, and optional advanced configuration.
public struct MeetingRoomPublisherSettings: Equatable, Hashable, Sendable {
    /// The username to display for this publisher.
    public var username: String
    /// Whether to publish audio stream.
    public var publishAudio: Bool
    /// Whether to publish video stream.
    public var publishVideo: Bool
    /// How video should be scaled in the view.
    public var scaleBehavior: MeetingRoomVideoScaleBehavior
    /// Optional advanced settings for fine-tuning video/audio configuration.
    public var advancedSettings: MeetingRoomPublisherAdvancedSettings?
    /// The initial video effect to apply.
    public var initialVideoEffect: MeetingRoomVideoEffect?
    /// The noise suppression state.
    public var noiseSuppressionState: MeetingRoomNoiseSuppressionState?

    /// Creates new publisher settings.
    public init(
        username: String = "",
        publishAudio: Bool = true,
        publishVideo: Bool = true,
        scaleBehavior: MeetingRoomVideoScaleBehavior = .fill,
        advancedSettings: MeetingRoomPublisherAdvancedSettings? = nil,
        initialVideoEffect: MeetingRoomVideoEffect? = nil,
        noiseSuppressionState: MeetingRoomNoiseSuppressionState? = nil
    ) {
        self.username = username
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
        self.scaleBehavior = scaleBehavior
        self.advancedSettings = advancedSettings
        self.initialVideoEffect = initialVideoEffect
        self.noiseSuppressionState = noiseSuppressionState
    }

    // MARK: - Fluent Interface Methods

    /// Sets the username and returns the modified settings.
    @discardableResult
    public func username(_ username: String) -> MeetingRoomPublisherSettings {
        var copy = self
        copy.username = username
        return copy
    }

    /// Sets whether to publish audio and returns the modified settings.
    @discardableResult
    public func publishAudio(_ publishAudio: Bool) -> MeetingRoomPublisherSettings {
        var copy = self
        copy.publishAudio = publishAudio
        return copy
    }

    /// Sets whether to publish video and returns the modified settings.
    @discardableResult
    public func publishVideo(_ publishVideo: Bool) -> MeetingRoomPublisherSettings {
        var copy = self
        copy.publishVideo = publishVideo
        return copy
    }

    /// Sets the video scale behavior and returns the modified settings.
    @discardableResult
    public func scaleBehavior(_ scaleBehavior: MeetingRoomVideoScaleBehavior) -> MeetingRoomPublisherSettings {
        var copy = self
        copy.scaleBehavior = scaleBehavior
        return copy
    }

    /// Sets the advanced settings and returns the modified settings.
    @discardableResult
    public func advancedSettings(
        _ advancedSettings: MeetingRoomPublisherAdvancedSettings?
    ) -> MeetingRoomPublisherSettings {
        var copy = self
        copy.advancedSettings = advancedSettings
        return copy
    }

    /// Sets the initial video effect and returns the modified settings.
    @discardableResult
    public func initialVideoEffect(_ initialVideoEffect: MeetingRoomVideoEffect?) -> MeetingRoomPublisherSettings {
        var copy = self
        copy.initialVideoEffect = initialVideoEffect
        return copy
    }

    /// Sets the noise suppression state and returns the modified settings.
    @discardableResult
    public func noiseSuppressionState(
        _ noiseSuppressionState: MeetingRoomNoiseSuppressionState?
    ) -> MeetingRoomPublisherSettings {
        var copy = self
        copy.noiseSuppressionState = noiseSuppressionState
        return copy
    }
}

// MARK: - Internal Conversion

import VERADomain

extension MeetingRoomVideoScaleBehavior {
    func toInternal() -> VideoScaleBehavior {
        switch self {
        case .fill: return .fill
        case .fit: return .fit
        }
    }
}

extension MeetingRoomNoiseSuppressionState {
    func toInternal() -> NoiseSuppressionState {
        switch self {
        case .enabled: return .enabled
        case .disabled: return .disabled
        case .idle: return .idle
        }
    }
}

extension MeetingRoomVideoEffect {
    func toInternal() -> VideoEffect {
        switch self {
        case .none: return .none
        case .blurLow: return .blurLow
        case .blurHigh: return .blurHigh
        case .backgroundImage(let id, let imagePath): return .backgroundImage(id: id, imagePath: imagePath)
        }
    }
}

extension MeetingRoomVideoResolution {
    func toInternal() -> VideoResolution {
        // Raw values match except for the typo in internal type
        switch self {
        case .low: return .low
        case .medium: return .mediun
        case .high: return .high
        case .high1080p: return .high1080p
        }
    }
}

extension MeetingRoomVideoFrameRate {
    func toInternal() -> VideoFrameRate {
        switch self {
        case .rate30FPS: return .rate30FPS
        case .rate15FPS: return .rate15FPS
        case .rate7FPS: return .rate7FPS
        case .rate1FPS: return .rate1FPS
        }
    }
}

extension MeetingRoomVideoCodecType {
    func toInternal() -> VideoCodecType {
        switch self {
        case .vp8: return .vp8
        case .h264: return .h264
        case .vp9: return .vp9
        }
    }
}

extension MeetingRoomVideoCodecPreference {
    func toInternal() -> VideoCodecPreference {
        VideoCodecPreference(
            automatic: automatic,
            codecs: codecs?.map { $0.toInternal() }
        )
    }
}

extension MeetingRoomVideoBitratePreset {
    func toInternal() -> VideoBitratePreset {
        switch self {
        case .default: return .default
        case .bwSaver: return .bwSaver
        case .extraBwSaver: return .extraBwSaver
        case .customBitrate: return .customBitrate
        }
    }
}

extension MeetingRoomDegradationPreference {
    func toInternal() -> DegradationPreference {
        switch self {
        case .notSet: return .notSet
        case .maintainFrameRateAndResolution: return .maintainFrameRateAndResolution
        case .maintainFrameRate: return .maintainFrameRate
        case .maintainResolution: return .maintainResolution
        case .balanced: return .balanced
        }
    }
}

extension MeetingRoomPublisherAdvancedSettings {
    func toInternal() -> PublisherAdvancedSettings {
        PublisherAdvancedSettings(
            videoResolution: videoResolution?.toInternal(),
            videoFrameRate: videoFrameRate?.toInternal(),
            preferredVideoCodecs: preferredVideoCodecs?.toInternal(),
            maxAudioBitrate: maxAudioBitrate,
            videoBitratePreset: videoBitratePreset?.toInternal(),
            maxVideoBitrate: maxVideoBitrate,
            publisherAudioFallbackEnabled: publisherAudioFallbackEnabled,
            subscriberAudioFallbackEnabled: subscriberAudioFallbackEnabled,
            degradationPreference: degradationPreference?.toInternal(),
            opusDtxEnabled: opusDtxEnabled
        )
    }
}

extension MeetingRoomPublisherSettings {
    func toInternal() -> PublisherSettings {
        PublisherSettings(
            username: username,
            publishAudio: publishAudio,
            publishVideo: publishVideo,
            scaleBehavior: scaleBehavior.toInternal(),
            advancedSettings: advancedSettings?.toInternal(),
            initialVideoEffect: initialVideoEffect?.toInternal(),
            noiseSuppressionState: noiseSuppressionState?.toInternal()
        )
    }
}
