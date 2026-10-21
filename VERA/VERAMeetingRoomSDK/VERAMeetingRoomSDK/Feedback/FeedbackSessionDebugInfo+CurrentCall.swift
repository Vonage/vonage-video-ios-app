//
//  Created by Vonage on 11/06/2026.
//

import VERADomain
import VERAFeedback
import VERAVonage

extension FeedbackSessionDebugInfo {
    /// Builds session debug info from the current call, when available.
    public static func fromCurrentCall(in sessionRepository: SessionRepository) -> FeedbackSessionDebugInfo {
        guard let call = sessionRepository.currentCall as? VonageCall,
            let session = call.session
        else {
            return .empty
        }

        return FeedbackSessionDebugInfo(
            sessionId: session.sessionId,
            connectionId: session.connectionId,
            connectionCreationTime: session.connectionCreationTime
        )
    }
}
