//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERACore
import VERADomain

public func makeMockCredentials(
    sessionId: String = "sessionId",
    token: String = "token",
    applicationId: String = "applicationId",
    captionsId: String? = "captionsId",
    roomName: String = "aRoomName",
    sessionKey: String = "aSessionKey"
) -> RoomCredentials {
    RoomCredentials(
        sessionId: sessionId,
        token: token,
        applicationId: "applicationId",
        roomName: roomName,
        sessionKey: sessionKey)
}
