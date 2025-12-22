//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

public struct MeetingRoomScreen: View {
    @ObservedObject var viewModel: MeetingRoomViewModel

    public init(viewModel: MeetingRoomViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            if case .content(let state) = viewModel.state {
                ZStack {
                    MeetingRoomView(
                        state: state,
                        actions: .init(
                            onShare: { _ in },
                            onRetry: {},
                            onToggleMic: viewModel.onToggleMic,
                            onToggleCamera: viewModel.onToggleCamera,
                            onCameraSwitch: viewModel.onCameraSwitch,
                            onEndCall: viewModel.endCall,
                            onToggleParticipants: {},
                            onToggleLayout: viewModel.onToggleLayout,
                            onShowChat: viewModel.showChat)
                    )

                    if state.callState == .disconnecting {
                        LoaderModalView()
                    }
                }
            }

            if case .loading = viewModel.state {
                LoaderModalView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(item: $viewModel.error) { $0.view }
        .onAppear {
            viewModel.loadUI()
        }
    }
}
