//
//  Created by Vonage on 13/10/25.
//

import Combine
import Foundation
import Testing
import VERAChat
import VERAChatAppTestHelpers
import VERAVonage
import VERAVonageChatPlugin

@MainActor
@Suite("Vonage Chat Plugin tests")
struct VonageChatPluginTests {

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

    @MainActor
    @Test("Default chat plugins keep independent histories and clear messages when a call ends")
    func defaultRepositoriesKeepIndependentCallHistories() {
        let first = VonageChatPlugin()
        let second = VonageChatPlugin()
        var firstMessages: [ChatMessage] = []
        var secondMessages: [ChatMessage] = []
        let firstSubscription = first.repository.observeMessages().sink { firstMessages = $0 }
        let secondSubscription = second.repository.observeMessages().sink { secondMessages = $0 }

        first.handleSignal(
            .init(
                type: "chat",
                data: #"{"participantName":"Customer","text":"hello"}"#
            )
        )

        #expect(firstMessages.map(\.username) == ["Customer"])
        #expect(firstMessages.map(\.message) == ["hello"])
        #expect(secondMessages.isEmpty)

        first.callDidEnd()

        #expect(firstMessages.isEmpty)
        #expect(secondMessages.isEmpty)
        withExtendedLifetime((firstSubscription, secondSubscription)) {}
    }

    @Test("A channel assigned off the main actor is used when sending")
    func channelAssignedOffMainActorIsUsedWhenSending() async throws {
        let sut = makeSUT()
        let channelSpy = SpyVonageSignalChannel()
        nonisolated(unsafe) let channel = channelSpy

        await Task.detached { sut.channel = channel }.value
        try sut.sendMessage("hello")

        #expect(channelSpy.recordedSignals.map(\.type) == [VonageChatPlugin.SignalType.chat.rawValue])
    }

    @Test("A channel cleared off the main actor stops sending")
    func channelClearedOffMainActorStopsSending() async {
        let sut = makeSUT()
        let channelSpy = SpyVonageSignalChannel()
        sut.channel = channelSpy

        await Task.detached { sut.channel = nil }.value

        #expect(throws: VonageChatPlugin.Error.missingChannel) { try sut.sendMessage("hello") }
        #expect(channelSpy.recordedSignals.isEmpty)
    }

    @Test("The channel is held weakly")
    func channelIsHeldWeakly() {
        let sut = makeSUT()
        var channelSpy: SpyVonageSignalChannel? = SpyVonageSignalChannel()
        sut.channel = channelSpy

        channelSpy = nil

        #expect(sut.channel == nil)
    }

    // MARK: SUT

    func makeSUT(
        repository: ChatMessagesRepository? = nil
    ) -> VonageChatPlugin {
        VonageChatPlugin(repository: repository ?? SpyChatMessagesRepository())
    }
}

extension AnyPublisher where Failure == Never {
    @MainActor
    func nextValue() async -> Output {
        for await value in values { return value }
        preconditionFailure("Expected a value before publisher completion")
    }
}
