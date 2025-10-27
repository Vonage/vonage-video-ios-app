//
//  Created by Vonage on 10/10/25.
//

import SwiftUI
import VERAChat
import VERAChatAppTestHelpers

@main
struct VERAChatApp: App {

    let chatFactory: ChatFactory

    init() {
        let repository = DefaultChatMessagesRepository(
            messages: ChatMessage.sampleMessages)
        let sendMessagesUseCase = MockSendChatMessageUseCase(
            name: "Me",
            chatMessagesRepository: repository
        )

        chatFactory = ChatFactory(
            chatMessagesRepository: repository,
            sendChatMessageUseCase: sendMessagesUseCase)
    }

    var body: some Scene {
        WindowGroup {
            chatFactory.make(onDismiss: {}).view
        }
    }
}
