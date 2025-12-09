//
//  Created by Vonage on 20/10/25.
//

import Combine
import Foundation
import Testing
import VERAChat
import VERAChatAppTestHelpers
import VERAVonage
import VERAVonageChatPlugin

@Suite("Vonage send chat messages tests")
struct VonageSendChatMessageUseCaseTests {

    @Test func whenSendingAMessageSendsAMessageRecordsAndSendThroughTheChannel() async throws {
        let repositorySpy = SpyChatMessagesRepository()
        let plugin = VonageChatPlugin(repository: repositorySpy)
        let sut = makeSUT(plugin)
        let channelSpy = SpyVonageSignalChannel()
        plugin.channel = channelSpy

        try sut("sent text")

        let sentSignal = channelSpy.recordedSignals.first!
        let sentMessage = try toChatMessage(sentSignal)

        #expect(sentSignal.type == "chat")
        #expect(sentMessage.username == "")
        #expect(sentMessage.message == "sent text")
    }

    @Test func whenSendingAMessageLocalUsernameIsUsed() async throws {
        let repositorySpy = SpyChatMessagesRepository()
        let plugin = VonageChatPlugin(repository: repositorySpy)
        let sut = makeSUT(plugin)
        let channelSpy = SpyVonageSignalChannel()
        plugin.channel = channelSpy

        let username = "Marvin"
        let params = [VonageCallParams.username.rawValue: username]
        plugin.callDidStart(params)

        try sut("sent text")

        let sentSignal = channelSpy.recordedSignals.first!
        let sentMessage = try toChatMessage(sentSignal)

        #expect(sentSignal.type == "chat")
        #expect(sentMessage.username == username)
        #expect(sentMessage.message == "sent text")
    }

    // MARK: SUT

    func makeSUT(_ plugin: VonageChatPlugin) -> VonageSendChatMessageUseCase {
        VonageSendChatMessageUseCase(vonageChatPlugin: plugin)
    }

    func toChatMessage(_ signal: OutgoingSignal) throws -> ChatMessage {
        guard let data = signal.payload else { fatalError("No data") }

        let decoder = JSONDecoder()
        let result = try decoder.decode(
            VonageChatMessage.self,
            from: data.data(using: .utf8)!)

        return .init(
            username: result.participantName,
            message: result.text,
            date: Date())
    }
}
