//
//  Created by Vonage on 30/06/2026.
//

import Foundation

/// Errors that can occur while fetching room credentials.
public enum RoomCredentialsError: Error, Equatable {
    case sessionKeyExpired
}

extension RoomCredentialsError: LocalizedError {
    /// Matches ``AlertItem/expiredLinkMessage`` so the user sees the same wording whether the expired
    /// session key was caught from an incoming deep link or from joining the meeting.
    public var errorDescription: String? {
        switch self {
        case .sessionKeyExpired:
            return AlertItem.expiredLinkMessage
        }
    }
}
