//
//  Created by Vonage on 29/7/25.
//

import Foundation
import SwiftUI
import VERACore

public func makeMockParticipant(
    id: String = "anId",
    name: String = "aName",
    isMicEnabled: Bool = true,
    isCameraEnabled: Bool = true,
    videoDimensions: CGSize? = .init(width: 640, height: 480),
    creationTime: Date = Date(timeIntervalSince1970: 1_754_638_879),
    view: AnyView = .init(EmptyView())
) -> Participant {
    .init(
        id: id,
        name: name,
        isMicEnabled: isMicEnabled,
        isCameraEnabled: isCameraEnabled,
        videoDimensions: videoDimensions,
        creationTime: creationTime,
        view: view
    )
}
