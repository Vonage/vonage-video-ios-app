//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public struct MeetingRoomScreen: View {
    @ObservedObject var viewModel: MeetingRoomViewModel
    private let onShowChat: () -> Void
    private let onBack: () -> Void

    public init(
        viewModel: MeetingRoomViewModel,
        onShowChat: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onShowChat = onShowChat
        self.onBack = onBack
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
                            onEndCall: {
                                viewModel.endCall()
                            },
                            onToggleParticipants: {},
                            onToggleLayout: viewModel.onToggleLayout,
                            onShowChat: onShowChat)
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
        .alert(item: $viewModel.error) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK")))
        }.onAppear {
            viewModel.loadUI()
        }.onChange(of: viewModel.state) { newValue in
            if case .content(let state) = newValue, state.callState == .disconnected {
                onBack()
            }
        }
    }
}
