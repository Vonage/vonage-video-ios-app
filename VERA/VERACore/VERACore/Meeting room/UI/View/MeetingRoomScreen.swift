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
    @State var showToast = false

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

            GeometryReader { geometry in
                VStack {
                    if showToast, let toast = viewModel.toast {
                        toast.view
                            .padding(.top, geometry.safeAreaInsets.top)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.toast) { newToast in
            if newToast != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showToast = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showToast = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        viewModel.toast = nil
                    }
                }
            }
        }
        .task {
            await viewModel.loadUI()
        }
    }
}

extension ToastItem {
    var view: ToastView {
        ToastView(item: self)
    }
}
