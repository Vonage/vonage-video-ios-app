//
//  Created by Vonage on 14/7/25.
//

import Combine
import SwiftUI

public struct WaitingRoomScreen: View {
    @ObservedObject private var viewModel: WaitingRoomViewModel
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
        case .content(let state):
            WaitingRoomView(
                state: state,
                userName: $viewModel.userName
            ) {
                Task {
                    await viewModel.joinRoom()
                    await MainActor.run {
                        onNavigateToRoom(state.roomName)
                    }
                }
            } onMicrophoneToggle: {
                viewModel.onMicToggle()
            } onCameraToggle: {
                viewModel.onCameraToggle()
            }
            .task {
                await viewModel.checkPermissions()
            }
        case .error(let error): Text(error)
        case .loading: Text("Loading", bundle: .veraCore)
        }
    }
}
