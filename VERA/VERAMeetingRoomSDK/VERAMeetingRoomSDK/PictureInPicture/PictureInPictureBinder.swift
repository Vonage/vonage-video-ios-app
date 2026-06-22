//
//  Created by Vonage on 21/6/26.
//

import Combine
import Foundation
import VERAMeetingRoom
import VERAVonage

/// Wires ``PictureInPictureManager`` to the meeting room view model and active call.
@MainActor
enum PictureInPictureBinder {
    static func bind(
        manager: PictureInPictureManager,
        viewModel: MeetingRoomViewModel,
        call: VonageCall
    ) -> AnyCancellable {
        manager.bind(to: call)

        return manager.$isInPictureInPicture
            .receive(on: DispatchQueue.main)
            .sink { isInPictureInPicture in
                viewModel.isInPictureInPicture = isInPictureInPicture
            }
    }
}
