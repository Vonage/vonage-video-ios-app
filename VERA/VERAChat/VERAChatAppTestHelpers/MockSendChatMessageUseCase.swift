//
//  Created by Vonage on 20/10/25.
//

import Foundation
import VERAChat

public final class MockSendChatMessageUseCase: SendChatMessageUseCase {
    private let chatMessagesRepository: any ChatMessagesRepository
    private let name: String

    public init(
        name: String,
        chatMessagesRepository: any ChatMessagesRepository
    ) {
        self.name = name
        self.chatMessagesRepository = chatMessagesRepository
    }

    public func callAsFunction(_ text: String) {
        chatMessagesRepository.addMessage(
            .init(username: name, message: text, date: Date()))
    }
}
