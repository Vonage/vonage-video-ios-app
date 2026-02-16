//
//  Created by Vonage on 29/7/25.
//

import Foundation
import SwiftUI
import VERADomain

public func makeMockParticipant(
    id: String = "anId",
    connectionId: String? = nil,
    name: String = "aName",
    isMicEnabled: Bool = true,
    isCameraEnabled: Bool = true,
    videoDimensions: CGSize = .init(width: 640, height: 480),
    creationTime: Date = Date(timeIntervalSince1970: 1_754_638_879),
    isScreenshare: Bool = false,
    isPinned: Bool = false,
    view: AnyView = AnyView(EmptyView())
) -> Participant {
    .init(
        id: id,
        connectionId: connectionId,
        name: name,
        isMicEnabled: isMicEnabled,
        isCameraEnabled: isCameraEnabled,
        videoDimensions: videoDimensions,
        creationTime: creationTime,
        isScreenshare: isScreenshare,
        isPinned: isPinned,
        view: view)
}
