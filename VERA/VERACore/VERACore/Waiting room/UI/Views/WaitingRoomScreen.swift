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
        case let .content(state):
            WaitingRoomView(
                state: state,
                userName: $viewModel.userName,
                publisherVideoView: viewModel.publisherVideoView
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
            .onAppear {
                viewModel.loadUI()
            }
            .task {
                await viewModel.checkPermissions()
            }
        case let .error(error): Text(error)
        case .loading: Text("Loading")
        }
    }
}
