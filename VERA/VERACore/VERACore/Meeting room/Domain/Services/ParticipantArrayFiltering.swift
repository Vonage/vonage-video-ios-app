//
//  Created by Vonage on 26/02/2026.
//

import Foundation
import VERADomain

// MARK: - Convenience Extensions

/// Convenience filtering helpers for participant arrays.
///
/// Provides simple, localized, and diacritic-insensitive search:
/// - Filters participants whose `name` contains the search text.
/// - Ignores case and diacritics to improve user experience.
extension Array where Element == Participant {

    /// Returns participants whose `name` matches the given search text.
    ///
    /// Filtering is **case-insensitive** and **diacritic-insensitive**.
    /// If the search text is empty, all participants are returned.
    ///
    /// - Parameter searchText: The text to search for in participant names.
    /// - Returns: A new array of participants matching the search criteria.
    public func filtered(by searchText: String) -> [Participant] {
        guard !searchText.isEmpty else {
            return self
        }

        return self.filter { participant in
            participant.name.range(
                of: searchText,
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            ) != nil
        }
    }
}
