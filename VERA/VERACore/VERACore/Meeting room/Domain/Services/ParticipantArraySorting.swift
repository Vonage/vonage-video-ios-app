//
//  Created by Vonage on 14/8/25.
//

import Foundation
import VERADomain

// MARK: - Convenience Extensions

/// Convenience sorting helpers for participant arrays.
///
/// Provides stable, user-friendly ordering for common views:
/// - By creation time (oldest-first), using name as a tiebreaker
/// - By name (localized, diacritic/case-insensitive), using creation time as a tiebreaker
extension Array where Element == Participant {

    /// Returns participants sorted by creation date (oldest first).
    ///
    /// When two participants share the same `creationTime`, the order is resolved
    /// with `localizedStandardCompare(_:)` on their `name` (diacritic and case-insensitive).
    ///
    /// - Returns: A new array sorted by `creationTime`, then `name` as tiebreaker.
    public func sortedByCreationDate() -> [Participant] {
        sorted { participantA, participantB in
            if participantA.creationTime == participantB.creationTime {
                return participantA.name.localizedStandardCompare(participantB.name) == .orderedAscending
            }
            return participantA.creationTime <= participantB.creationTime
        }
    }

    /// Returns participants sorted by name using localized, diacritic- and case-insensitive comparison.
    ///
    /// When two participants have the same `name` according to `localizedStandardCompare(_:)`,
    /// the order falls back to `creationTime` (oldest first) to ensure stable ordering.
    ///
    /// - Returns: A new array sorted by `name`, then `creationTime` as tiebreaker.
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
