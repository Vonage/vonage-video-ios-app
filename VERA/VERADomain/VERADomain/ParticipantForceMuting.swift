//
//  Created by Vonage on 25/6/26.
//

import Foundation

/// Provides moderation controls for force-muting remote participants.
public protocol ParticipantForceMuting: AnyObject {
    /// Forces the remote participant identified by `id` to stop publishing audio.
    func forceMuteParticipant(id: String) async throws
}

extension ParticipantForceMuting {
    /// Default implementation for call implementations that do not support force mute.
    public func forceMuteParticipant(id: String) async throws {
        throw ParticipantForceMuteError.unsupported
    }
}

/// Errors raised before a force-mute request reaches the underlying call service.
public enum ParticipantForceMuteError: LocalizedError, Equatable {
    case participantNotFound
    case unsupported

    public var errorDescription: String? {
        switch self {
        case .participantNotFound:
            return "The participant is no longer in the call."
        case .unsupported:
            return "Force mute is not supported for this call."
        }
    }
}
