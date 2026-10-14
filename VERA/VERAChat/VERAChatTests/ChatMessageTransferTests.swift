//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERAChat

@Suite("Chat message value transfer")
struct ChatMessageTransferTests {

    @Test("Message snapshots preserve every field across tasks and an actor")
    func messagesAcrossTasksAndActor() async {
        let messages = [
            ChatMessage(username: "Zaphod", message: "Hello", date: Date(timeIntervalSince1970: 1_760_000_000)),
            ChatMessage(
                username: "会議 🚀", message: "A quoted \"message\"\nSecond line", date: Date(timeIntervalSince1970: 0)),
        ]
        let history = ChatHistory()

        for snapshot in [[], messages] {
            let received = await Task.detached { snapshot }.value
            #expect(received.map(\.username) == snapshot.map(\.username))
            #expect(received.map(\.message) == snapshot.map(\.message))
            #expect(received.map(\.date) == snapshot.map(\.date))

            await history.update(received)
            let stored = await history.messages
            #expect(stored.map(\.username) == snapshot.map(\.username))
            #expect(stored.map(\.message) == snapshot.map(\.message))
            #expect(stored.map(\.date) == snapshot.map(\.date))
        }
    }
}

private actor ChatHistory {
    private(set) var messages: [ChatMessage] = []

    func update(_ values: [ChatMessage]) {
        messages = values
    }
}
