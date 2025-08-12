//
//  Created by Vonage on 15/7/25.
//

import Foundation

public enum VideoScaleBehavior: String, Equatable {
    case fill
    case fit
}

public struct PublisherSettings {
    public let username: String
    public let publishAudio: Bool
    public let publishVideo: Bool
    public let scaleBehavior: VideoScaleBehavior

    public init(
        username: String = "",
        publishAudio: Bool = true,
        publishVideo: Bool = true,
        scaleBehavior: VideoScaleBehavior = .fill
    ) {
        self.username = username
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
        self.scaleBehavior = scaleBehavior
    }
}

public protocol PublisherFactory {
    func make(_ settings: PublisherSettings) async -> VERAPublisher
}
