//
//  Created by Vonage on 14/8/25.
//

import Foundation

// MARK: - Convenience Extensions

extension Array where Element == Participant {

    /**
     * Convenience method to sort participants by creation date
     * Uses name as tiebreaker for identical creation times (diacritic and case insensitive)
     * @returns New sorted array of participants
     */
    public func sortedByCreationDate() -> [Participant] {
        sorted { participantA, participantB in
            if participantA.creationTime == participantB.creationTime {
                return participantA.name.localizedStandardCompare(participantB.name) == .orderedAscending
            }
            return participantA.creationTime <= participantB.creationTime
        }
    }

    /**
     * Convenience method to sort participants by name
     * Uses creation time as tiebreaker for identical names
     * @returns New sorted array of participants
     */
    public func sortedByName() -> [Participant] {
        sorted { participantA, participantB in
            let nameComparison = participantA.name.localizedStandardCompare(participantB.name)
            if nameComparison == .orderedSame {
                return participantA.creationTime <= participantB.creationTime
            }
            return nameComparison == .orderedAscending
        }
    }
}
