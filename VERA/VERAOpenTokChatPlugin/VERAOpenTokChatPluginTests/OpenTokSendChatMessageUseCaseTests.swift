//
//  Created by Vonage on 20/10/25.
//

import Combine
import Foundation
import Testing
import VERAChat
import VERAChatAppTestHelpers
import VERAOpenTok
import VERAOpenTokChatPlugin

@Suite("OpenTok send chat messages tests")
struct OpenTokSendChatMessageUseCaseTests {

    @Test func whenSendingAMessageSendsAMessageRecordsAndSendThroughTheChannel() async throws {
        let repositorySpy = SpyChatMessagesRepository()
        let plugin = OpenTokChatPlugin(repository: repositorySpy)
        let sut = makeSUT(plugin)
        let channelSpy = SpyOpenTokSignalChannel()
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
        let plugin = OpenTokChatPlugin(repository: repositorySpy)
        let sut = makeSUT(plugin)
        let channelSpy = SpyOpenTokSignalChannel()
        plugin.channel = channelSpy

        let username = "Marvin"
        let params = [OpenTokCallParams.username.rawValue: username]
        plugin.callDidStart(params)

        try sut("sent text")

        let sentSignal = channelSpy.recordedSignals.first!
        let sentMessage = try toChatMessage(sentSignal)

        #expect(sentSignal.type == "chat")
        #expect(sentMessage.username == username)
        #expect(sentMessage.message == "sent text")
    }

    // MARK: SUT

    func makeSUT(_ plugin: OpenTokChatPlugin) -> OpenTokSendChatMessageUseCase {
        OpenTokSendChatMessageUseCase(openTokChatPlugin: plugin)
    }

    func toChatMessage(_ signal: OutgoingSignal) throws -> ChatMessage {
        guard let data = signal.payload else { fatalError("No data") }

        let decoder = JSONDecoder()
        let result = try decoder.decode(
            OpenTokChatMessage.self,
            from: data.data(using: .utf8)!)

        return .init(
            username: result.participantName,
            message: result.text,
            date: Date())
    }
}
