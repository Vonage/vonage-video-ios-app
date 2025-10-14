//
//  Created by Vonage on 14/10/25.
//

import SwiftUI

public class ChatFactory {

    private let chatMessagesRepository: any ChatMessagesRepository

    public init(chatMessagesRepository: any ChatMessagesRepository) {
        self.chatMessagesRepository = chatMessagesRepository
    }

    public func make(
        onDismiss: @escaping () -> Void
    ) -> (view: some View, viewModel: ChatPanelViewModel) {
        let viewModel = ChatPanelViewModel(
            chatMessagesRepository: chatMessagesRepository)
        return (
            ChatScreen(viewModel: viewModel, onDismiss: onDismiss),
            viewModel
        )
    }
}
