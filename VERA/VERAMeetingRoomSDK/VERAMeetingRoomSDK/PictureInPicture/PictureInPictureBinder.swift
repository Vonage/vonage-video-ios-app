//
//  Created by Vonage on 21/6/26.
//

import Combine
import Foundation
import VERAMeetingRoom
import VERAVonage

/// Wires ``PictureInPictureSessionOrchestrator`` to the active call and meeting room UI state.
@MainActor
enum PictureInPictureBinder {
    static func bind(
        orchestrator: PictureInPictureSessionOrchestrator,
        call: VonageCall,
        viewModel: MeetingRoomViewModel
    ) {
        orchestrator.bind(to: call)
        viewModel.bindPictureInPictureTargetParticipantId(
            orchestrator.$pipTargetParticipantId.eraseToAnyPublisher()
        )
    }
}
