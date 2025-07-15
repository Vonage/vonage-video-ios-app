//
//  Created by Vonage on 15/7/25.
//

import Foundation
import Combine

public typealias WaitingRoomError = String

public enum WaitingRoomViewState: Equatable {
    case loading
    case error(WaitingRoomError)
    case success(RoomName)
    case content(WaitingRoomState)
}

public final class WaitingRoomViewModel: ObservableObject {
    @Published public var state: WaitingRoomViewState = .content(WaitingRoomState.default)
    @Published public var userName: String = ""
    
    init(roomName: RoomName) {
        self.state = .content(WaitingRoomState.default)
        
        
    }
}
