//
//  Created by Vonage on 11/2/26.
//

import Foundation

/// Errors that can occur while mapping signal payloads to reactions.
public enum ReactionMappingError: LocalizedError {
    /// Signal payload is missing or empty.
    case missingData

    /// JSON payload is invalid or cannot be decoded.
    case invalidJSON

    /// Participant name is empty or invalid.
    case invalidParticipantName

    /// Emoji is empty or invalid.
    case invalidEmoji

    public var errorDescription: String? {
        switch self {
        case .missingData:
            return "Signal data is missing or empty"
        case .invalidJSON:
            return "Invalid JSON format in signal data"
        case .invalidParticipantName:
            return "Participant name is empty or invalid"
        case .invalidEmoji:
            return "Emoji is empty or invalid"
        }
    }
}
