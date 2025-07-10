//
//  Created by Vonage on 8/7/25.
//

import Foundation
import VERACore

enum AppRoute: Hashable, Equatable {
    case landing
    case meetingRoom(RoomName)
    case waitingRoom(RoomName)
    case goodbye

    init?(path: String) {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = trimmed.components(separatedBy: "/")

        switch components {
        case ["landing"]:
            self = .landing
        case let components where components.count == 2 && components[0] == "room":
            self = .meetingRoom(components[1])
        case let components where components.count == 2 && components[0] == "waiting":
            self = .waitingRoom(components[1])
        case ["goodbye"]:
            self = .goodbye
        default:
            return nil
        }
    }

    var path: String {
        switch self {
        case .landing:
            return "/landing"
        case .meetingRoom(let id):
            return "/room/\(id)"
        case .waitingRoom(let id):
            return "/waiting/\(id)"
        case .goodbye:
            return "/goodbye"
        }
    }
}
