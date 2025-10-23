//
//  Created by Vonage on 14/10/25.
//

import Combine
import Foundation
import Testing
import VERAChat
import VERAChatAppTestHelpers

@Suite("Chat panel view model tests")
struct ChatPanelViewModelTests {

    @Test func initialStateIsLoading() {
        let repository = SpyChatMessagesRepository()
        let sendMessageUseCase = makeSendChatMessageUseCase(repository: repository)
        let sut = makeSUT(sendChatMessageUseCase: sendMessageUseCase)

        #expect(sut.state == .loading)
    }

    @Test func callToLoadDataChangesStateToContent() async {
        let repository = SpyChatMessagesRepository()
        let sendMessageUseCase = makeSendChatMessageUseCase(repository: repository)
        let sut = makeSUT(sendChatMessageUseCase: sendMessageUseCase)

        var value = await sut.$state.values.first { _ in true }

        #expect(value == .loading)

        sut.loadData()

        value = await sut.$state.values.first { state in
            if case .content = state {
                return true
            }
            return false
        }

        #expect(value == .content(.default))
    }

    @Test func callToLoadDataWithMessagesChangesStateToContent() async {
        let repository = SpyChatMessagesRepository()
        let sendMessageUseCase = makeSendChatMessageUseCase(repository: repository)
        let inputMessages = makeMessages()
        repository.subject.value = inputMessages
        let sut = makeSUT(
            repository: repository,
            sendChatMessageUseCase: sendMessageUseCase)

        var value = await sut.$state.values.first { _ in true }

        #expect(value == .loading)

        sut.loadData()

        value = await sut.$state.values.first { state in
            if case .content = state {
                return true
            }
            return false
        }

        guard case .content(let chatState) = value else {
            Issue.record("Expected content state")
            return
        }

        let messages = chatState.messages

        #expect(messages.count == 2)

        let actualMessages = chatState.messages
        let expectedMessages = inputMessages.map { $0.toUIChatMessage }

        #expect(actualMessages == expectedMessages)
    }

    @Test func sendMessageCallsToSendMessageUseCase() async {
        let repository = SpyChatMessagesRepository()
        let sendMessageUseCase = makeSendChatMessageUseCase(repository: repository)
        let sut = makeSUT(repository: repository,
                          sendChatMessageUseCase: sendMessageUseCase)
        
        sut.sendMessage("Don't panic!")

        let messages = await repository.observeMessages().values.first { _ in true }
        #expect(messages!.first!.message == "Don't panic!")
    }
    
    // MARK: SUT

    func makeSUT(
        repository: ChatMessagesRepository = SpyChatMessagesRepository(),
        sendChatMessageUseCase: SendChatMessageUseCase
    ) -> ChatPanelViewModel {
        .init(
            chatMessagesRepository: repository,
            sendChatMessageUseCase: sendChatMessageUseCase)
    }

    func makeSendChatMessageUseCase(
        name: String = "Me",
        repository: ChatMessagesRepository
    ) -> SendChatMessageUseCase {
        MockSendChatMessageUseCase(
            name: name,
            chatMessagesRepository: repository)
    }

    func makeMessages() -> [ChatMessage] {
        [
            .init(
                username: "an username",
                message: "a message",
                date: Date(timeIntervalSince1970: 1_760_453_194)),
            .init(
                username: "another username",
                message: "another message",
                date: Date(timeIntervalSince1970: 1_760_463_194)),
        ]
    }

    func makeUIMessages() -> [UIChatMessage] {
        [
            UIChatMessage(
                id: 0,
                username: "a username",
                message: "a message",
                date: "16:46"),
            UIChatMessage(
                id: 0,
                username: "another username",
                message: "another message",
                date: "19:33"),
        ]
    }
}
