//
//  Created by Vonage on 14/10/25.
//

import Combine
import Foundation
import Testing
import VERAChat
import VERAChatAppTestHelpers

@Suite("Chat pannel view model tests")
struct ChatPanelViewModelTests {

    @Test func initialStateIsLoading() {
        let sut = makeSUT()

        #expect(sut.state == .loading)
    }

    @Test func callToLoadDataChangesStateToContent() {
        let sut = makeSUT()

        #expect(sut.state == .loading)

        sut.loadData()

        #expect(sut.state == .content(.default))
    }

    @Test func callToLoadDataWithMessagesChangesStateToContent() {
        let repository = SpyChatMessagesRepository()
        let inputMessages = makeMessages()
        repository.subject.value = inputMessages
        let sut = makeSUT(repository: repository)

        #expect(sut.state == .loading)

        sut.loadData()

        guard case .content(let chatState) = sut.state else {
            Issue.record("Expected content state")
            return
        }

        let messages = chatState.messages

        #expect(messages.count == 2)

        let actualMessages = chatState.messages
        let expectedMessages = inputMessages.map { $0.toUIChatMessage }

        #expect(actualMessages == expectedMessages)
    }

    @Test func sendingMessagesNotifiesToTheRepository() async throws {
        let repository = SpyChatMessagesRepository()
        let sut = makeSUT(repository: repository)

        var didSend = false
        repository.onSendMessage = { _ in
            didSend = true
        }

        sut.sendMessage("a message")

        #expect(didSend)
    }

    // MARK: SUT

    func makeSUT(
        repository: ChatMessagesRepository = SpyChatMessagesRepository()
    ) -> ChatPanelViewModel {
        .init(chatMessagesRepository: repository)
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
