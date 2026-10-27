//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERAVonage
import VERAVonageChatPlugin

@Suite("Chat signal payload value transfer")
struct ChatPayloadTransferTests {

    @Test("Wire payloads preserve their JSON field names and values across tasks and an actor")
    func payloadsAcrossTasksAndActor() async throws {
        let payloads = [
            VonageChatMessage(participantName: "Zaphod", text: "Hello"),
            VonageChatMessage(participantName: " 会議 🚀\n", text: " A quoted \"message\"\nSecond line "),
        ]
        let received = await Task.detached { payloads }.value
        #expect(received.map(\.participantName) == payloads.map(\.participantName))
        #expect(received.map(\.text) == payloads.map(\.text))

        let selection = ChatPayloadSelection()
        for (payload, expected) in zip(received, payloads) {
            await selection.update(payload)
            let stored = await selection.payload
            #expect(stored.participantName == expected.participantName)
            #expect(stored.text == expected.text)

            let encoded = Data(try stored.toJSONString().utf8)
            let fields = try JSONDecoder().decode([String: String].self, from: encoded)
            #expect(fields == ["participantName": expected.participantName, "text": expected.text])
            let decoded = try JSONDecoder().decode(VonageChatMessage.self, from: encoded)
            #expect(decoded.participantName == expected.participantName)
            #expect(decoded.text == expected.text)
        }
    }

    @Test("Transferred wire payloads retain trimming and a supplied mapping timestamp")
    func mappingTransferredPayload() async throws {
        let payload = VonageChatMessage(participantName: " \n会議 🚀\t", text: " \tHello\nSecond line \n")
        let received = await Task.detached { payload }.value
        let date = Date(timeIntervalSince1970: 1_760_000_000)
        let signal = VonageSignal(type: "chat", data: try received.toJSONString())

        let message = try signal.toChatMessage(date: date)

        #expect(message.username == "会議 🚀")
        #expect(message.message == "Hello\nSecond line")
        #expect(message.date == date)
    }

    @Test("Whitespace-only names and messages retain their existing validation errors")
    func whitespaceValidation() throws {
        let emptyName = VonageChatMessage(participantName: " \n\t", text: "Hello")
        let emptyMessage = VonageChatMessage(participantName: "Zaphod", text: " \n\t")

        do {
            _ = try VonageSignal(type: "chat", data: emptyName.toJSONString()).toChatMessage()
            Issue.record("Expected invalidParticipantName for a whitespace-only name")
        } catch ChatMappingError.invalidParticipantName {
        }

        do {
            _ = try VonageSignal(type: "chat", data: emptyMessage.toJSONString()).toChatMessage()
            Issue.record("Expected emptyMessage for whitespace-only content")
        } catch ChatMappingError.emptyMessage {
        }
    }
}

private actor ChatPayloadSelection {
    private(set) var payload = VonageChatMessage(participantName: "", text: "")

    func update(_ value: VonageChatMessage) {
        payload = value
    }
}
