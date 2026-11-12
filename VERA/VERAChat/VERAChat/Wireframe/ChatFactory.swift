//
//  Created by Vonage on 14/10/25.
//

import SwiftUI

@MainActor
public class ChatFactory {

    private let chatMessagesRepository: any ChatMessagesRepository
    private let sendChatMessageUseCase: SendChatMessageUseCase

    public init(
        chatMessagesRepository: any ChatMessagesRepository,
        sendChatMessageUseCase: SendChatMessageUseCase
    ) {
        self.chatMessagesRepository = chatMessagesRepository
        self.sendChatMessageUseCase = sendChatMessageUseCase
    }

    @MainActor
    public func make(
        onDismiss: @escaping () -> Void
    ) -> (view: some View, viewModel: ChatPanelViewModel) {
        let viewModel = ChatPanelViewModel(
            chatMessagesRepository: chatMessagesRepository,
            sendChatMessageUseCase: sendChatMessageUseCase)
        return (
            ChatScreen(viewModel: viewModel, onDismiss: onDismiss),
            viewModel
        )
    }
}
