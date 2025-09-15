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

public final class ActiveSpeakerTracker: ObservableObject {
    private let minimumAudioLevelThreshold: Float

    @Published public private(set) var activeSpeaker: ActiveSpeakerInfo = .none

    private var cancellables = Set<AnyCancellable>()

    public init(minimumAudioLevelThreshold: Float = 0.2) {
        self.minimumAudioLevelThreshold = minimumAudioLevelThreshold
    }

    // MARK: - Public Methods

    public func updatedParticipant(_ participant: SpeakerInfo) {
        guard participant.isMicEnabled, participant.audioLevel >= minimumAudioLevelThreshold else { return }

        if participant.audioLevel > activeSpeaker.audioLevel {
            activeSpeaker = ActiveSpeakerInfo(
                participantId: participant.id,
                audioLevel: participant.audioLevel
            )
        }
    }

    public func calculateActiveSpeaker(from participants: [SpeakerInfo]) {
        let eligibleParticipants = participants.filter { participant in
            guard participant.isMicEnabled else { return false }

            guard participant.audioLevel >= minimumAudioLevelThreshold else { return false }

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

        if newActiveSpeaker.participantId != activeSpeaker.participantId
            && newActiveSpeaker.audioLevel >= minimumAudioLevelThreshold
        {
            // New participant becomes active speaker
            activeSpeaker = newActiveSpeaker
        } else if newActiveSpeaker.participantId == activeSpeaker.participantId
            && newActiveSpeaker.audioLevel >= minimumAudioLevelThreshold
        {
            // Same participant but update audio level
            activeSpeaker = newActiveSpeaker
        } else if newActiveSpeaker.participantId == nil && activeSpeaker.participantId != nil {
            // No eligible participants, clear active speaker
            activeSpeaker = .none
        }
    }

    public func reset() {
        activeSpeaker = .none
    }
}
