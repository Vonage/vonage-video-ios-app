//
//  Created by Vonage on 8/8/25.
//

import Foundation

/// Utility for sorting participants by their display priority.
///
/// Priority order (highest to lowest):
/// 1. Screenshare participants
/// 2. Pinned participants
/// 3. Active speaker participant
/// 4. Other participants (maintains current order)
public struct ParticipantDisplayPriority {

    /**
     * Sorts participants by their display priority.
     * @param participants Array of participants to sort
     * @param activeSpeakerId The ID of the current active speaker, or nil if none
     * @returns Sorted array of participants
     */
    public static func sortByDisplayPriority(
        participants: [Participant],
        activeSpeakerId: String?
    ) -> [Participant] {
        return participants.sorted { participantA, participantB in
            return compareDisplayPriority(
                participantA: participantA,
                participantB: participantB,
                activeSpeakerId: activeSpeakerId
            ) < 0
        }
    }

    /**
     * Compares two participants for display priority sorting.
     * @param participantA First participant to compare
     * @param participantB Second participant to compare
     * @param activeSpeakerId The ID of the current active speaker, or nil if none
     * @returns Comparison result: -1 if A has higher priority, 1 if B has higher priority, 0 if equal
     */
    private static func compareDisplayPriority(
        participantA: Participant,
        participantB: Participant,
        activeSpeakerId: String?
    ) -> Int {

        // Priority 1: Screenshare participants come first
        if participantA.isScreenshare && !participantB.isScreenshare {
            return -1
        }
        if !participantA.isScreenshare && participantB.isScreenshare {
            return 1
        }

        // Priority 2: Pinned participants come next
        if participantA.isPinned && !participantB.isPinned {
            return -1
        }
        if !participantA.isPinned && participantB.isPinned {
            return 1
        }

        // If both are pinned, maintain current order
        if participantA.isPinned && participantB.isPinned {
            return 0
        }

        // Priority 3: Active speaker comes next
        let aIsActiveSpeaker = participantA.id == activeSpeakerId
        let bIsActiveSpeaker = participantB.id == activeSpeakerId

        if aIsActiveSpeaker && !bIsActiveSpeaker {
            return -1
        }
        if !aIsActiveSpeaker && bIsActiveSpeaker {
            return 1
        }

        // Priority 4: If no higher priority applies, maintain current order
        return 0
    }
}

// MARK: - Convenience Extensions

extension Array where Element == Participant {

    /**
     * Convenience method to sort participants by display priority
     * @param activeSpeakerId The ID of the current active speaker, or nil if none
     * @returns New sorted array of participants
     */
    public func sortedByDisplayPriority(activeSpeakerId: String?) -> [Participant] {
        return ParticipantDisplayPriority.sortByDisplayPriority(
            participants: self,
            activeSpeakerId: activeSpeakerId
        )
    }
}
