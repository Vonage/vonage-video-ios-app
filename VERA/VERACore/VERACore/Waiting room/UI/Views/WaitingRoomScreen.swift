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
                toolbarButtons: $viewModel.toolbarButtons,
                extraTrailingButtons: $viewModel.extraTrailingButtons,
                audioOutputTestButton: viewModel.audioOutputTestButton
            ) {
                Task {
                    await viewModel.joinRoom()
                }
            } onMicrophoneToggle: {
                viewModel.onToggleMic()
            } onCameraToggle: {
                viewModel.onToggleCamera()
            }
            .onAppear {
                viewModel.loadUI()
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    ForEach(viewModel.toolbarButtons) { holder in
                        holder.content()
                    }
                }
            }
        case .loading: Text("Loading", bundle: .veraCore)
        }
    }
}
