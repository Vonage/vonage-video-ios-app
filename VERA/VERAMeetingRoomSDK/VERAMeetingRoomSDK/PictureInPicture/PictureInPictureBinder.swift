//
//  Created by Vonage on 21/6/26.
//

import Foundation
import VERAVonage

/// Wires ``PictureInPictureManager`` to the active call.
@MainActor
enum PictureInPictureBinder {
    static func bind(
        manager: PictureInPictureManager,
        call: VonageCall
    ) {
        manager.bind(to: call)
    }
}
