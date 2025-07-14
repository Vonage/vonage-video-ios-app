//
//  Created by Vonage on 14/7/25.
//

import SwiftUI
import Combine

public typealias WaitingRoomError = String

public enum WaitingRoomViewState: Equatable {
    case loading
    case error(WaitingRoomError)
    case success(RoomName)
    case content(WaitingRoomState)
}

public final class WaitingRoomViewModel {
    @Published public var state: WaitingRoomViewState = .content(WaitingRoomState.default)
    
    init(roomName: RoomName) {
        self.state = .content(WaitingRoomState.default)
    }
}

public struct WaitingRoomScreen: View {
    private let viewModel: WaitingRoomViewModel
    private let onNavigateToRoom: (RoomName) -> Void

    public init(
        viewModel: WaitingRoomViewModel,
        onNavigateToRoom: @escaping (RoomName) -> Void
    ) {
        self.viewModel = viewModel
        self.onNavigateToRoom = onNavigateToRoom
    }
    
    public var body: some View {
        switch viewModel.state {
        case let .content(state):
            WaitingRoomView(state: state) { username in
                onNavigateToRoom(state.roomName)
            }
            
        case let .error(error): Text(error)
        case let .success(roomName): Text(roomName)
        case .loading:  Text("Loading")
        }
    }
}
