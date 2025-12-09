//
//  Created by Vonage on 8/8/25.
//

import Foundation
import VERADomain

/// Utility for sorting participants by their display priority.
///
/// Display priority (highest → lowest):
/// 1. Screenshare participants
/// 2. Pinned participants
/// 3. Active speaker participant
/// 4. Others (creation date ascending, name as tiebreaker)
///
/// Use this to order participants for grid/list views so focus stays on the most relevant tiles.
public struct ParticipantDisplayPriority {

    /// Sorts participants by the display priority rules.
    ///
    /// Applies the priority order, then falls back to creation date (oldest first)
    /// and localized name comparison when needed to ensure stable, user-friendly ordering.
    ///
    /// - Parameters:
    ///   - participants: Array of participants to sort.
    ///   - activeSpeakerId: The ID of the current active speaker, or `nil` if none.
    /// - Returns: A new array of participants sorted by display priority.
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

    /// Compares two participants according to the display priority rules.
    ///
    /// - Parameters:
    ///   - participantA: First participant to compare.
    ///   - participantB: Second participant to compare.
    ///   - activeSpeakerId: The ID of the current active speaker, or `nil` if none.
    /// - Returns: `-1` if A has higher priority, `1` if B has higher priority, `0` if equal.
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

        // Priority 4: If no higher priority applies, sort by creation date with name as tiebreaker
        if participantA.creationTime == participantB.creationTime {
            let nameComparison = participantA.name.localizedStandardCompare(participantB.name)
            return nameComparison == .orderedAscending ? -1 : (nameComparison == .orderedDescending ? 1 : 0)
        }
        return participantA.creationTime <= participantB.creationTime ? -1 : 1
    }

    /// Sorts participants by their creation date (oldest first).
    ///
    /// - Parameter participants: Array of participants.
    /// - Returns: A new array sorted by `creationTime` ascending.
    public static func sortByDate(
        participants: [Participant]
    ) -> [Participant] {
        return participants.sorted { participantA, participantB in
            participantA.creationTime <= participantB.creationTime
        }
    }

    /// Sorts participants by their name (lexicographic).
    ///
    /// - Parameter participants: Array of participants.
    /// - Returns: A new array sorted by `name` ascending.
    public static func sortByName(
        participants: [Participant]
    ) -> [Participant] {
        return participants.sorted { participantA, participantB in
            participantA.name <= participantB.name
        }
    }
}

// MARK: - Convenience Extensions

/// Convenience method on arrays of participants to sort by display priority.
extension Array where Element == Participant {

    /// Returns participants sorted by display priority.
    ///
    /// - Parameter activeSpeakerId: The ID of the current active speaker, or `nil` if none.
    /// - Returns: A new array sorted by display priority.
    public func sortedByDisplayPriority(activeSpeakerId: String?) -> [Participant] {
        return ParticipantDisplayPriority.sortByDisplayPriority(
            participants: self,
            activeSpeakerId: activeSpeakerId
        )
    }
}
