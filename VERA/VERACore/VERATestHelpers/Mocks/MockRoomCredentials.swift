//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERACore

public func makeMockCredentials(
    sessionId: String = "sessionId",
    token: String = "token",
    applicationId: String = "applicationId",
    captionsId: String? = "captionsId",
    roomName: String = "aRoomName"
) -> RoomCredentials {
    RoomCredentials(
        sessionId: sessionId,
        token: token,
        applicationId: "applicationId",
        roomName: roomName)
}
