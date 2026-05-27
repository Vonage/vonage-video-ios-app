//
//  Created by Vonage on 21/05/2026.
//

import Foundation

/// Aggregated network statistics for a single remote subscriber.
///
/// Groups audio receive stats, video receive stats, and media link stats
/// for one subscriber, identified by their connection ID.
public struct SubscriberMediaStats: Equatable, Identifiable {
    /// Unique identifier for the subscriber (connection ID).
    public var id: String { subscriberID }

    /// The subscriber's connection ID from the Vonage session.
    public let subscriberID: String
    /// The subscriber's display name from the stream.
    public let subscriberName: String
    /// Audio statistics for this subscriber's incoming stream.
    public let receivedAudio: AudioReceiveStats?
    /// Video statistics for this subscriber's incoming stream.
    public let receivedVideo: VideoReceiveStats?
    /// Transport-level media link statistics for this subscriber.
    public let mediaLinkStats: SubscriberMediaLinkStats?

    public init(
        subscriberID: String,
        subscriberName: String,
        receivedAudio: AudioReceiveStats? = nil,
        receivedVideo: VideoReceiveStats? = nil,
        mediaLinkStats: SubscriberMediaLinkStats? = nil
    ) {
        self.subscriberID = subscriberID
        self.subscriberName = subscriberName
        self.receivedAudio = receivedAudio
        self.receivedVideo = receivedVideo
        self.mediaLinkStats = mediaLinkStats
    }
}
