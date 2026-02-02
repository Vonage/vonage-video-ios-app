//
//  Created by Vonage on 14/7/25.
//

import Combine
import SwiftUI
import VERACommonUI
import VERADomain

public struct WaitingRoomScreen: View {
    @ObservedObject private var viewModel: WaitingRoomViewModel

    public init(
        viewModel: WaitingRoomViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
        switch viewModel.state {
        case .content(let state):
            WaitingRoomView(
                state: state,
                userName: $viewModel.userName,
                extraTrailingButtons: $viewModel.extraTrailingButtons,
            ) {
                Task {
                    await viewModel.joinRoom()
                }
            } onMicrophoneToggle: {
                viewModel.onMicToggle()
            } onCameraToggle: {
                viewModel.onCameraToggle()
            }
            .task {
                await viewModel.checkPermissions()
            }
            .onAppear {
                viewModel.loadUI()
            }
            .alert(item: $viewModel.error) { $0.view }
        case .loading: Text("Loading", bundle: .veraCore)
        }
    }
}
