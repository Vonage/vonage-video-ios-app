//
//  Created by Vonage on 13/10/25.
//

import Combine
import Foundation
import Testing
import VERAChat
import VERAChatAppTestHelpers
import VERAOpenTok
import VERAOpenTokChatPlugin

@Suite("OpenTok Chat Plugin tests")
struct OpenTokChatPluginTests {

    @Test func newSignalAddsAMessageToTheRepository() async throws {
        let repositorySpy = SpyChatMessagesRepository()

        let sut = makeSUT(repository: repositorySpy)

        #expect(await repositorySpy.observeMessages().nextValue().isEmpty)

        sut.handleSignal(
            .init(
                type: "chat",
                data: "{\"participantName\": \"Zaphod\", \"text\": \"a text\"}"))

        let value = (await repositorySpy.observeMessages().nextValue()).first!

        let expectedMessage = ChatMessage(
            username: "Zaphod",
            message: "a text",
            date: Date())

        #expect(value.username == expectedMessage.username)
        #expect(value.message == expectedMessage.message)
    }

    @Test func whenCallEndsAllTheRecordedMessagesAreRemoved() async throws {
        let repositorySpy = SpyChatMessagesRepository()

        let sut = makeSUT(repository: repositorySpy)

        #expect(await repositorySpy.observeMessages().nextValue().isEmpty)

        sut.handleSignal(
            .init(
                type: "chat",
                data: "{\"participantName\": \"Zaphod\", \"text\": \"a text\"}"))

        let value = (await repositorySpy.observeMessages().nextValue()).first!

        let expectedMessage = ChatMessage(
            username: "Zaphod",
            message: "a text",
            date: Date())

        #expect(value.username == expectedMessage.username)
        #expect(value.message == expectedMessage.message)

        sut.callDidEnd()

        let storedMessages = await repositorySpy.observeMessages().nextValue()

        #expect(storedMessages.isEmpty)
    }

    // MARK: SUT

    func makeSUT(
        repository: ChatMessagesRepository = SpyChatMessagesRepository()
    ) -> OpenTokChatPlugin {
        OpenTokChatPlugin(repository: repository)
    }
}

extension AnyPublisher where Failure == Never {
    func nextValue() async -> Output {
        await values.first { _ in true }!
    }
}
