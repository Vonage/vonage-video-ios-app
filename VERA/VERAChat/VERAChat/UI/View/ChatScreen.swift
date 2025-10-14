//
//  Created by Vonage on 14/10/25.
//

import SwiftUI
import VERACommonUI

public struct ChatScreen: View {

    @ObservedObject var viewModel: ChatPanelViewModel
    let onDismiss: () -> Void

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .content(let chatPannelState):
                    ChatPanel(
                        messages: chatPannelState.messages,
                        onSendMessage: { message in
                            viewModel.sendMessage(message)
                        }
                    )
                case .loading:
                    ProgressView()
                        .onAppear {
                            viewModel.loadData()
                        }
                @unknown default: fatalError("Unknown case")
                }
            }
            .navigationTitle("Chat")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                        }.tint(.label)
                    }
                #else
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                        }
                    }
                #endif
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
