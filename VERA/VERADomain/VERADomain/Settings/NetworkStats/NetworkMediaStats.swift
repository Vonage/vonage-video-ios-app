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
    /// Audio statistics for the local publisher (send direction).
    public let sentAudio: AudioSendStats?
    /// Video statistics for the local publisher (send direction).
    public let sentVideo: VideoSendStats?
    /// Audio statistics for a remote subscriber (receive direction).
    public let receivedAudio: AudioReceiveStats?
    /// Video statistics for a remote subscriber (receive direction).
    public let receivedVideo: VideoReceiveStats?

    public static let empty = NetworkMediaStats()

    public init(
        sentAudio: AudioSendStats? = nil,
        sentVideo: VideoSendStats? = nil,
        receivedAudio: AudioReceiveStats? = nil,
        receivedVideo: VideoReceiveStats? = nil
    ) {
        self.sentAudio = sentAudio
        self.sentVideo = sentVideo
        self.receivedAudio = receivedAudio
        self.receivedVideo = receivedVideo
    }
}
