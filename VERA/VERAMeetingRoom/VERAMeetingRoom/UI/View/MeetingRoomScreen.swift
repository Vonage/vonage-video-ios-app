//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

private enum MeetingRoomScreenConstants {
    static let overlaysPaddingFromBottom: CGFloat = 64
}

public struct MeetingRoomScreen: View {
    @ObservedObject var viewModel: MeetingRoomViewModel

    public init(
        viewModel: MeetingRoomViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
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
                                onToggleLayout: viewModel.onToggleLayout),
                            extraButtons: $viewModel.extraButtons,
                            extraTopTrailingButtons: $viewModel.extraTopTrailingButtons
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

            GeometryReader { _ in
                VStack { Spacer() }
                    .frame(maxWidth: .infinity)
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toast(toast: $viewModel.toast, placement: .top, verticalPadding: 8)
        .task {
            await viewModel.loadUI()
        }
    }
}
