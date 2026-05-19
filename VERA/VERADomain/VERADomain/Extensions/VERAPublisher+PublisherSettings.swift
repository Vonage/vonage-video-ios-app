//
//  Created by Vonage on 23/4/26.
//

extension VERAPublisher {
    /// Returns a snapshot of the current publisher state as ``PublisherSettings``.
    ///
    /// - Parameters:
    ///   - username: The display name to embed in the settings.
    ///   - advancedSettings: Optional advanced configuration to carry over.
    /// - Returns: A ``PublisherSettings`` reflecting the current audio/video state.
    public func publisherSettings(
        username: String = "",
        advancedSettings: PublisherAdvancedSettings? = nil
    ) -> PublisherSettings {
        PublisherSettings(
            username: username,
            publishAudio: publishAudio,
            publishVideo: publishVideo,
            advancedSettings: advancedSettings
        )
    }
}
