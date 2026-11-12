//
//  Created by Vonage on 01/07/2026.
//

import Foundation

public protocol RoomIdentifier: Equatable {
    var roomName: RoomName { get }
}

public struct PlainRoomIdentifier: RoomIdentifier, Sendable {
    public let roomName: RoomName

    public init(roomName: RoomName) {
        self.roomName = roomName
    }
}

public struct SessionKeyRoomIdentifier: RoomIdentifier, Sendable {
    public var roomName: RoomName {
        SessionKeyParser.extractRoomName(from: sessionKey) ?? ""
    }
    public let sessionKey: String

    public init(sessionKey: String) {
        self.sessionKey = sessionKey
    }
}
