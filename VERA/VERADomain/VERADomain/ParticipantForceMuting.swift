//
//  Created by Vonage on 25/6/26.
//

import Foundation

/// Provides moderation controls for force-muting remote participants.
///
/// This capability is intentionally separate from ``CallFacade`` because it is
/// available only to call implementations backed by a moderation-capable service.
public protocol ParticipantForceMuting: AnyObject {
    /// Forces the remote participant identified by `id` to stop publishing audio.
    func forceMuteParticipant(id: String) async throws
}

/// Errors raised before a force-mute request reaches the underlying call service.
public enum ParticipantForceMuteError: LocalizedError, Equatable {
    case participantNotFound

    public var errorDescription: String? {
        switch self {
        case .participantNotFound:
            return "The participant is no longer in the call."
        }
    }
}
