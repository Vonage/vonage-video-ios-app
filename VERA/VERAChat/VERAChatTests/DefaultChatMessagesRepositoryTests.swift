//
//  Created by Vonage on 14/10/25.
//

import Combine
import Foundation
import Testing
import VERAChat

@MainActor
@Suite("Default Chat Messages Repository tests")
struct DefaultChatMessagesRepositoryTests {

    @Test func initialStateContainsZeroMessages() async throws {
        let sut = makeSUT()

        let value = currentMessages(from: sut.observeMessages())

        #expect(value == [])
    }

    @Test func addingMessagesCanBeObserved() async throws {
        let sut = makeSUT()

        let firstMessage = ChatMessage(
            username: "an username",
            message: "a message",
            date: Date(timeIntervalSince1970: 1_760_453_194))

        let secondMessage = ChatMessage(
            username: "another username",
            message: "a message",
            date: Date(timeIntervalSince1970: 1_760_463_194))

        sut.addMessage(firstMessage)
        sut.addMessage(secondMessage)

        let value = currentMessages(from: sut.observeMessages())

        #expect(value == [firstMessage, secondMessage])
    }

    @Test func clearMessagesClearsTheStoredMessages() async throws {
        let sut = makeSUT()

        let firstMessage = ChatMessage(
            username: "an username",
            message: "a message",
            date: Date(timeIntervalSince1970: 1_760_453_194))

        let secondMessage = ChatMessage(
            username: "another username",
            message: "a message",
            date: Date(timeIntervalSince1970: 1_760_463_194))

        sut.addMessage(firstMessage)
        sut.addMessage(secondMessage)

        let publisher = sut.observeMessages()
        var value = currentMessages(from: publisher)

        #expect(value == [firstMessage, secondMessage])

        sut.clearMessages()

        value = currentMessages(from: publisher)

        #expect(value == [])
    }

    // MARK: SUT

    /// These UI-owned repositories synchronously replay their current message snapshot.
    private func currentMessages(from publisher: AnyPublisher<[ChatMessage], Never>) -> [ChatMessage]? {
        var messages: [ChatMessage]?
        let subscription = publisher.first().sink { messages = $0 }
        defer { subscription.cancel() }
        return messages
    }

    func makeSUT(
        messages: [ChatMessage] = []
    ) -> DefaultChatMessagesRepository {
        .init(messages: messages)
    }
}
