//
//  Created by Vonage on 15/7/25.
//

import Foundation

public struct PublisherSettings {
    public let username: String
    public let publishAudio: Bool
    public let publishVideo: Bool

    public init(
        username: String = "",
        publishAudio: Bool = true,
        publishVideo: Bool = true
    ) {
        self.username = username
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
    }
}

public protocol PublisherFactory {
    func make(_ settings: PublisherSettings) async -> VERAPublisher
}
