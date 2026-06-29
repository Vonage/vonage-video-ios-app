//
//  Created by Vonage on 21/6/26.
//

import Combine
import Foundation
import VERAMeetingRoom
import VERAVonage

/// Wires ``PictureInPictureManager`` to the active call and meeting room UI state.
@MainActor
enum PictureInPictureBinder {
    static func bind(
        manager: PictureInPictureManager,
        call: VonageCall,
        viewModel: MeetingRoomViewModel
    ) {
        manager.bind(to: call)
        viewModel.bindPictureInPictureTargetParticipantId(
            manager.$pipTargetParticipantId.eraseToAnyPublisher()
        )
    }
}
