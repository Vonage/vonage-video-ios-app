//
//  Created by Vonage on 29/7/25.
//

import Foundation

public struct SessionState {
    public let isPublishingAudio: Bool
    public let isPublishingVideo: Bool

    public static var initial: SessionState {
        .init(
            isPublishingAudio: false,
            isPublishingVideo: false
        )
    }

    public init(isPublishingAudio: Bool, isPublishingVideo: Bool) {
        self.isPublishingAudio = isPublishingAudio
        self.isPublishingVideo = isPublishingVideo
    }
}
