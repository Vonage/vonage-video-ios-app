//
//  Created by Vonage on 10/10/25.
//

import SwiftUI
import VERAChat
import VERAChatAppTestHelpers

@main
struct VERAChatAppApp: App {

    let chatFactory: ChatFactory

    init() {
        let repository = DefaultChatMessagesRepository(
            messages: ChatMessage.sampleMessages)

        repository.onSendMessage = { [weak repository] message in
            repository?.addMessage(
                .init(username: "Me", message: message, date: Date())
            )
        }

        chatFactory = ChatFactory(
            chatMessagesRepository: repository)
    }

    var body: some Scene {
        WindowGroup {
            chatFactory.make(onDismiss: {}).view
        }
    }
}
