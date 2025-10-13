//
//  Created by Vonage on 10/10/25.
//

import SwiftUI
import VERAChat
import VERAChatAppTestHelpers

@main
struct VERAChatAppApp: App {

    let repository: ChatMessagesRepository
    @ObservedObject var viewModel: ChatPanelViewModel

    init() {
        repository = DefaultChatMessagesRepository(messages: ChatMessage.sampleMessages)
        viewModel = ChatPanelViewModel(chatMessagesRepository: repository)
    }

    var body: some Scene {
        WindowGroup {
            switch viewModel.state {
            case .content(let chatPannelState):
                ChatPanel(
                    messages: chatPannelState.messages,
                    onSendMessage: { message in
                        addMessage(message)
                    }
                )
            case .error(let string):
                Text(string)
            case .loading:
                ProgressView()
                    .onAppear {
                        viewModel.loadData()
                    }
            @unknown default: fatalError("Unknown case")
            }
        }
    }

    func addMessage(_ message: String) {
        repository.addMessage(
            .init(
                username: "Me",
                message: message,
                date: Date()))
    }
}
