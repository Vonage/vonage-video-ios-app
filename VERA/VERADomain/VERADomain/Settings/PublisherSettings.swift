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
public struct PublisherSettings: Equatable {
    /// The username to display for this publisher.
    public let username: String

    /// Whether to publish audio stream.
    public let publishAudio: Bool

    /// Whether to publish video stream.
    public let publishVideo: Bool

    /// How video should be scaled in the view.
    public let scaleBehavior: VideoScaleBehavior

    /// Optional advanced settings for fine-tuning video/audio configuration.
    public let advancedSettings: PublisherAdvancedSettings?

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
        advancedSettings: PublisherAdvancedSettings? = nil
    ) {
        self.username = username
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
        self.scaleBehavior = scaleBehavior
        self.advancedSettings = advancedSettings
    }
}
