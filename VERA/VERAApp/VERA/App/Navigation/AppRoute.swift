//
//  Created by Vonage on 6/10/25.
//

import Foundation

public enum AppRoute: Hashable {
    case landing
    case waitingRoom(String)
    case meetingRoom(String)
    case goodbye(String)
    case settings

    var description: String {
        switch self {
        case .landing: "Landing"
        case .waitingRoom(let room): "Waiting room (\(room))"
        case .meetingRoom(let room): "Meeting room (\(room))"
        case .goodbye: "Goodbye"
        case .settings: "Settings"
        }
    }
}
