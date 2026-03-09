//
//  Created by Vonage on 22/1/26.
//

import Foundation

extension URL {
    public func meetingRoomURL(_ roomName: RoomName) -> URL {
        appendingPathComponent("room")
            .appendingPathComponent(roomName)
    }
}
