//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public struct MeetingRoomScreen: View {
    @ObservedObject var viewModel: MeetingRoomViewModel
    private let onCopyToClipboard: (String) -> Void
    private let onBack: () -> Void

    public init(
        viewModel: MeetingRoomViewModel,
        onCopyToClipboard: @escaping (String) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onCopyToClipboard = onCopyToClipboard
        self.onBack = onBack
    }

    public var body: some View {
        VStack {
            if case let .content(state) = viewModel.state {
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
                            onBack()
                        },
                        onToggleParticipants: {},
                        onToggleLayout: viewModel.onToggleLayout,
                        onCopyToClipboard: onCopyToClipboard)
                )
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
        }
    }
}
