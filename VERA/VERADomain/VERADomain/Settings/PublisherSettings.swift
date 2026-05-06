//
//  Created by Vonage on 01/03/2026.
//

/// Basic publisher configuration settings.
///
/// Contains fundamental settings for creating a video publisher, including user identity,
/// media publishing flags, display behavior, and optional advanced configuration.
///
/// This is the primary settings type used when joining a room or creating a publisher.
///
/// - SeeAlso: ``PublisherAdvancedSettings``, ``VideoScaleBehavior``
public struct PublisherSettings: Equatable, Hashable {
    /// The username to display for this publisher.
    public var username: String

    /// Whether to publish audio stream.
    public var publishAudio: Bool

    /// Whether to publish video stream.
    public var publishVideo: Bool

    /// How video should be scaled in the view.
    public var scaleBehavior: VideoScaleBehavior

    /// Optional advanced settings for fine-tuning video/audio configuration.
    public var advancedSettings: PublisherAdvancedSettings?

    public var backgroundBlurLevel: BlurLevel?

    public var noiseSuppressionState: NoiseSuppressionState?

    /// Creates new publisher settings.
    ///
    /// - Parameters:
    ///   - username: The username to display. Defaults to empty string.
    ///   - publishAudio: Whether to publish audio. Defaults to `true`.
    ///   - publishVideo: Whether to publish video. Defaults to `true`.
    ///   - scaleBehavior: Video scaling behavior. Defaults to `.fill`.
    ///   - advancedSettings: Optional advanced configuration. Defaults to `nil`.
    public init(
        username: String = "",
        publishAudio: Bool = true,
        publishVideo: Bool = true,
        scaleBehavior: VideoScaleBehavior = .fill,
        advancedSettings: PublisherAdvancedSettings? = nil,
        backgroundBlurLevel: BlurLevel? = nil,
        noiseSuppressionState: NoiseSuppressionState? = nil
    ) {
        self.username = username
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
        self.scaleBehavior = scaleBehavior
        self.advancedSettings = advancedSettings
        self.backgroundBlurLevel = backgroundBlurLevel
        self.noiseSuppressionState = noiseSuppressionState
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(username)
        hasher.combine(publishAudio)
        hasher.combine(publishVideo)
        hasher.combine(scaleBehavior)
        hasher.combine(advancedSettings)
        hasher.combine(backgroundBlurLevel)
        hasher.combine(noiseSuppressionState)
    }

    // MARK: - Fluent Interface Methods

    /// Sets the username and returns the modified settings.
    @discardableResult
    public func username(_ username: String) -> PublisherSettings {
        var copy = self
        copy.username = username
        return copy
    }

    /// Sets whether to publish audio and returns the modified settings.
    @discardableResult
    public func publishAudio(_ publishAudio: Bool) -> PublisherSettings {
        var copy = self
        copy.publishAudio = publishAudio
        return copy
    }

    /// Sets whether to publish video and returns the modified settings.
    @discardableResult
    public func publishVideo(_ publishVideo: Bool) -> PublisherSettings {
        var copy = self
        copy.publishVideo = publishVideo
        return copy
    }

    /// Sets the video scale behavior and returns the modified settings.
    @discardableResult
    public func scaleBehavior(_ scaleBehavior: VideoScaleBehavior) -> PublisherSettings {
        var copy = self
        copy.scaleBehavior = scaleBehavior
        return copy
    }

    /// Sets the advanced settings and returns the modified settings.
    @discardableResult
    public func advancedSettings(_ advancedSettings: PublisherAdvancedSettings?) -> PublisherSettings {
        var copy = self
        copy.advancedSettings = advancedSettings
        return copy
    }

    /// Sets the background blur level and returns the modified settings.
    @discardableResult
    public func backgroundBlurLevel(_ backgroundBlurLevel: BlurLevel?) -> PublisherSettings {
        var copy = self
        copy.backgroundBlurLevel = backgroundBlurLevel
        return copy
    }

    /// Sets the noise suppression state and returns the modified settings.
    @discardableResult
    public func noiseSuppressionState(_ noiseSuppressionState: NoiseSuppressionState?) -> PublisherSettings {
        var copy = self
        copy.noiseSuppressionState = noiseSuppressionState
        return copy
    }
}
