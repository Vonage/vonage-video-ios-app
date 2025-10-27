//
//  Created by Vonage on 14/10/25.
//

import Combine
import Foundation
import Testing
import VERAChat

@Suite("Default Chat Messages Repository tests")
struct DefaultChatMessagesRepositoryTests {

    @Test func initialStateContainsZeroMessages() async throws {
        let sut = makeSUT()

        let value = await sut.observeMessages().values.first { _ in true }

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

        let value = await sut.observeMessages().values.first { _ in true }

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
        var value = await publisher.values.first { _ in true }

        #expect(value == [firstMessage, secondMessage])

        sut.clearMessages()

        value = await publisher.values.first { _ in true }

        #expect(value == [])
    }

    // MARK: SUT

    func makeSUT(
        messages: [ChatMessage] = []
    ) -> DefaultChatMessagesRepository {
        .init(messages: messages)
    }
}
