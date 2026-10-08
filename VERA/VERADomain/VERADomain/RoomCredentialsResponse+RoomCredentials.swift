//
//  Created by Vonage on 28/9/26.
//

import Foundation

extension RoomCredentialsResponse {
    public func asRoomCredentials(with roomName: RoomName) -> RoomCredentials {
        .init(
            sessionId: sessionId,
            token: token,
            applicationId: apiKey,
            roomName: roomName,
            sessionKey: sessionKey,
            captionsId: captionsId)
    }
}
