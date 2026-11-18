//
//  Created by Vonage on 19/10/26.
//

import Combine
import Foundation
import Testing
import VERAChat
import VERAChatAppTestHelpers

@MainActor
@Suite("Chat publisher executor boundary")
struct ChatPublisherDeliveryTests {
    @Test("Background messages update UI-owned panel and unread badge state")
    func acceptsBackgroundRepositoryDelivery() async {
        let message = ChatMessage(username: "Alice", message: "Hello", date: .distantPast)
        let repository = BackgroundChatRepository(messages: [message])
        let panel = ChatPanelViewModel(
            chatMessagesRepository: repository,
            sendChatMessageUseCase: MockSendChatMessageUseCase(name: "Me", chatMessagesRepository: repository))
        let badge = ChatBadgeButtonViewModel(chatMessagesObserver: repository)
        panel.loadData()
        let expectedState = ChatPanelViewState.content(ChatPanelState(messages: [message.toUIChatMessage]))

        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while ContinuousClock.now < deadline {
            if panel.state == expectedState && badge.unreadMessagesCount == 1 { break }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(panel.state == expectedState)
        #expect(badge.unreadMessagesCount == 1)
        badge.chatDidOpen()
        #expect(badge.unreadMessagesCount == 0)
    }
}

private final class BackgroundChatRepository: ChatMessagesRepository {
    private let messages: [ChatMessage]
    private let queue = DispatchQueue(label: "chat-ui-test-delivery")

    init(messages: [ChatMessage]) {
        self.messages = messages
    }

    func observeMessages() -> AnyPublisher<[ChatMessage], Never> {
        Just(messages)
            .subscribe(on: queue)
            .map { @Sendable messages in
                #expect(!Thread.isMainThread)
                return messages
            }
            .eraseToAnyPublisher()
    }

    func addMessage(_ message: ChatMessage) {}
    func clearMessages() {}
}
