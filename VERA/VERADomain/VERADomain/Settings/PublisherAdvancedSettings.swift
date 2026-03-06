//
//  Created by Vonage on 02/03/2026.
//

/// Advanced publisher configuration settings for fine-tuning video and audio quality.
///
/// Derived from VERASettings' ``PublisherSettingsPreferences`` and applied to the publisher
/// during creation or runtime updates. All properties are optional, allowing partial configuration.
///
/// This type is converted to OpenTok SDK settings in VERAVonage module.
///
/// - SeeAlso: ``PublisherSettings``, ``VideoResolution``, ``VideoFrameRate``, ``VideoCodecPreference``
public struct PublisherAdvancedSettings: Equatable {
    /// The desired video capture resolution.
    public let videoResolution: VideoResolution?
    
    /// The desired video capture frame rate.
    public let videoFrameRate: VideoFrameRate?
    
    /// Codec selection preference (automatic or manual with ordered list).
    public let preferredVideoCodecs: VideoCodecPreference?
    
    /// Maximum audio bitrate in bits per second.
    public let maxAudioBitrate: Int32?
    
    /// Video bitrate preset (default, bandwidth saver, etc.).
    public let videoBitratePreset: VideoBitratePreset?
    
    /// Maximum video bitrate in bits per second (only used when `videoBitratePreset` is `.customBitrate`).
    public let maxVideoBitrate: Int32?
    
    /// Whether audio fallback is enabled for the publisher.
    public let publisherAudioFallbackEnabled: Bool?
    
    /// Whether audio fallback is enabled for subscribers.
    public let subscriberAudioFallbackEnabled: Bool?

    /// Creates new advanced publisher settings.
    ///
    /// All parameters are optional, allowing you to configure only the settings you need.
    ///
    /// - Parameters:
    ///   - videoResolution: The video capture resolution.
    ///   - videoFrameRate: The video capture frame rate.
    ///   - preferredVideoCodecs: Codec selection preference.
    ///   - maxAudioBitrate: Maximum audio bitrate in bps.
    ///   - videoBitratePreset: Video bitrate strategy.
    ///   - maxVideoBitrate: Custom maximum video bitrate in bps.
    ///   - publisherAudioFallbackEnabled: Publisher audio fallback flag.
    ///   - subscriberAudioFallbackEnabled: Subscriber audio fallback flag.
    public init(
        videoResolution: VideoResolution? = nil,
        videoFrameRate: VideoFrameRate? = nil,
        preferredVideoCodecs: VideoCodecPreference? = nil,
        maxAudioBitrate: Int32? = nil,
        videoBitratePreset: VideoBitratePreset? = nil,
        maxVideoBitrate: Int32? = nil,
        publisherAudioFallbackEnabled: Bool? = nil,
        subscriberAudioFallbackEnabled: Bool? = nil
    ) {
        self.videoResolution = videoResolution
        self.videoFrameRate = videoFrameRate
        self.preferredVideoCodecs = preferredVideoCodecs
        self.maxAudioBitrate = maxAudioBitrate
        self.videoBitratePreset = videoBitratePreset
        self.maxVideoBitrate = maxVideoBitrate
        self.publisherAudioFallbackEnabled = publisherAudioFallbackEnabled
        self.subscriberAudioFallbackEnabled = subscriberAudioFallbackEnabled
    }
}
