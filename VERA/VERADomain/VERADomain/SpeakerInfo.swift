//
//  Created by Vonage on 14/04/2026.
//

import Foundation

public struct SpeakerInfo {
    public let id: String
    public let audioLevel: Float
    public let isMicEnabled: Bool

    public init(
        id: String,
        audioLevel: Float = 0.0,
        isMicEnabled: Bool
    ) {
        self.id = id
        self.audioLevel = audioLevel
        self.isMicEnabled = isMicEnabled
    }
}

extension Participant {
    public func getSpeakerInfo(_ audioLevel: Float) -> SpeakerInfo {
        .init(id: id, audioLevel: audioLevel, isMicEnabled: isMicEnabled)
    }
}
