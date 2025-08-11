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
    private static let MINIMUM_AUDIO_LEVEL_THRESHOLD: Float = 0.2

    @Published public private(set) var activeSpeaker: ActiveSpeakerInfo = .none

    private var cancellables = Set<AnyCancellable>()

    public init() {}

    // MARK: - Public Methods

    public func calculateActiveSpeaker(from participants: [Participant]) {
        let eligibleParticipants = participants.filter { participant in
            guard participant.isMicEnabled else { return false }

            guard participant.audioLevel >= Self.MINIMUM_AUDIO_LEVEL_THRESHOLD else { return false }

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
            && newActiveSpeaker.audioLevel >= Self.MINIMUM_AUDIO_LEVEL_THRESHOLD
        {
            // New participant becomes active speaker
            activeSpeaker = newActiveSpeaker
        } else if newActiveSpeaker.participantId == activeSpeaker.participantId
            && newActiveSpeaker.audioLevel >= Self.MINIMUM_AUDIO_LEVEL_THRESHOLD
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
