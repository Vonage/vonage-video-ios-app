//
//  Created by Vonage on 6/8/25.
//

import Combine
import Foundation
import SwiftUI

public struct ActiveSpeakerInfo: Equatable {
    public let participantId: String?
    /// The audio level of the active speaker (0.0 - 1.0)
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

    var activeSpeakerInfo: ActiveSpeakerInfo {
        .init(participantId: id, audioLevel: audioLevel)
    }

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

/// Tracks and determines the active speaker in a meeting based on audio levels
/// and microphone status.
///
/// The `ActiveSpeakerTracker` monitors participant audio levels and automatically determines
/// who should be considered the "active speaker" based on configurable thresholds.
/// It provides real-time updates through Combine's `@Published` properties.
///
/// ## Usage
/// ```swift
/// let tracker = ActiveSpeakerTracker(minimumAudioLevelThreshold: 0.3)
///
/// // Calculate from all participants
/// tracker.calculateActiveSpeaker(from: allParticipants)
///
/// // Update individual participant
/// let participant = SpeakerInfo(id: "user123", audioLevel: 0.8, isMicEnabled: true)
/// tracker.updatedParticipant(participant)
/// ```
///
/// ## Active Speaker Logic
/// - Only participants with enabled microphones are considered
/// - Audio level must meet the minimum threshold to become active speaker
/// - The participant with the highest qualifying audio level becomes active speaker
/// - Current active speaker's audio level is always updated, even if below threshold
public final class ActiveSpeakerTracker: ObservableObject {
    private let minimumAudioLevelThreshold: Float

    @Published public private(set) var activeSpeaker: ActiveSpeakerInfo = .none

    private var cancellables = Set<AnyCancellable>()

    public init(minimumAudioLevelThreshold: Float = 0.2) {
        self.minimumAudioLevelThreshold = minimumAudioLevelThreshold
    }

    // MARK: - Public Methods

    /// When the audio level of a participant is updated is compared against the
    /// current active participant.
    /// If the updated participant is the current one the audio level is updated
    public func updatedParticipant(_ participant: SpeakerInfo) {
        // We have to update current active participant audio level,
        // otherwise the participant with highest audio level will remain
        if activeSpeaker.participantId == participant.id {
            activeSpeaker = participant.activeSpeakerInfo
            return
        }
        guard participant.isMicEnabled, participant.audioLevel >= minimumAudioLevelThreshold else { return }

        if participant.audioLevel > activeSpeaker.audioLevel {
            activeSpeaker = participant.activeSpeakerInfo
        }
    }

    /// Calculates the active speaker given a list of participant audio
    /// information
    public func calculateActiveSpeaker(from participants: [SpeakerInfo]) {
        let eligibleParticipants = participants.filter { participant in
            guard participant.isMicEnabled else { return false }

            guard participant.audioLevel >= minimumAudioLevelThreshold else { return false }

            return true
        }

        let newActiveSpeaker: ActiveSpeakerInfo

        if let loudestParticipant = eligibleParticipants.max(by: { $0.audioLevel < $1.audioLevel }) {
            newActiveSpeaker = loudestParticipant.activeSpeakerInfo
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
