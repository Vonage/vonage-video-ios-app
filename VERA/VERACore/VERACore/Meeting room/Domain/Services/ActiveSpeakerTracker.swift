//
//  Created by Vonage on 6/8/25.
//

import Combine
import Foundation
import SwiftUI

public struct ActiveSpeakerInfo: Equatable {
    public let participantId: String?
    public let audioLevel: Float

    public init(participantId: String? = nil, audioLevel: Float = 0.0) {
        self.participantId = participantId
        self.audioLevel = audioLevel
    }

    public static let none = ActiveSpeakerInfo()
}

public final class ActiveSpeakerTracker: ObservableObject {
    private static let MINIMUM_AUDIO_LEVEL_THRESHOLD: Float = 0.15
    private static let AUDIO_LEVEL_TIMEOUT: TimeInterval = 3.0
    private static let SPEAKER_CHANGE_COOLDOWN: TimeInterval = 1.0

    @Published public private(set) var activeSpeaker: ActiveSpeakerInfo = .none

    private var lastSpeakerChangeTime: Date = Date.distantPast
    private var cancellables = Set<AnyCancellable>()

    public init() {}

    // MARK: - Public Methods

    public func calculateActiveSpeaker(from participants: [Participant]) {
        let now = Date()

        guard now.timeIntervalSince(lastSpeakerChangeTime) >= Self.SPEAKER_CHANGE_COOLDOWN else {
            return
        }

        let eligibleParticipants = participants.filter { participant in
            guard participant.isMicEnabled else { return false }

            guard participant.audioLevel >= Self.MINIMUM_AUDIO_LEVEL_THRESHOLD else { return false }

            let timeSinceLastUpdate = now.timeIntervalSince(participant.lastAudioLevelUpdate)
            guard timeSinceLastUpdate <= Self.AUDIO_LEVEL_TIMEOUT else { return false }

            return true
        }

        let newActiveSpeaker: ActiveSpeakerInfo

        if let loudestParticipant = eligibleParticipants.max(by: { $0.audioLevel < $1.audioLevel }) {
            newActiveSpeaker = ActiveSpeakerInfo(
                participantId: loudestParticipant.id,
                audioLevel: loudestParticipant.audioLevel
            )
        } else {
            newActiveSpeaker = .none
        }

        if newActiveSpeaker != activeSpeaker {
            activeSpeaker = newActiveSpeaker
            lastSpeakerChangeTime = now
        }
    }

    public func reset() {
        activeSpeaker = .none
        lastSpeakerChangeTime = Date.distantPast
    }
}
