//
//  Created by Vonage on 23/04/2026.
//

import Foundation

public struct NewRoomRequest: Equatable, Hashable {
    public let roomName: RoomName
    public let publisherSettings: PublisherSettings

    public init(
        roomName: RoomName,
        publisherSettings: PublisherSettings = .init()
    ) {
        self.roomName = roomName
        self.publisherSettings = publisherSettings
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(roomName)
        hasher.combine(publisherSettings)
    }
}
