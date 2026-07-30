//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Aggregated network statistics for audio and video media in both send and receive directions.
///
/// Published by ``NetworkStatsProvider/networkStatsPublisher`` and consumed by the
/// statistics UI in VERASettings. Each field is optional to accommodate partial updates
/// (e.g. stats may arrive for the publisher before any subscriber connects).
public struct NetworkMediaStats: Equatable {
    /// Display name of the local publisher.
    public let publisherName: String
    /// Audio statistics for the local publisher (send direction).
    public let sentAudio: AudioSendStats?
    /// Video statistics for the local publisher (send direction).
    public let sentVideo: VideoSendStats?
    /// Per-subscriber statistics, one entry per remote participant.
    public let subscriberStats: [SubscriberMediaStats]
    /// Transport-level statistics for the publisher's uplink connection.
    public let publisherMediaLinkStats: PublisherMediaLinkStats?

    public static let empty = NetworkMediaStats()

    public init(
        publisherName: String = "",
        sentAudio: AudioSendStats? = nil,
        sentVideo: VideoSendStats? = nil,
        subscriberStats: [SubscriberMediaStats] = [],
        publisherMediaLinkStats: PublisherMediaLinkStats? = nil
    ) {
        self.publisherName = publisherName
        self.sentAudio = sentAudio
        self.sentVideo = sentVideo
        self.subscriberStats = subscriberStats
        self.publisherMediaLinkStats = publisherMediaLinkStats
    }
}
