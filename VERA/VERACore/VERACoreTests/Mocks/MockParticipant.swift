//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERACore
import SwiftUI

func makeMockParticipant(
    id: String = "anId",
    name: String = "aName",
    isMicEnabled: Bool = true,
    isCameraEnabled: Bool = true,
    view: AnyView = .init(EmptyView())
) -> Participant {
    .init(
        id: id,
        name: name,
        isMicEnabled: isMicEnabled,
        isCameraEnabled: isCameraEnabled,
        view: view
    )
}
