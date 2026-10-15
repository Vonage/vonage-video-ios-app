//
//  Created by Vonage on 15/10/26.
//

import Testing
import VERAChat

@Suite("Chat panel snapshot transfers")
struct ChatPanelStateTransferTests {
    @Test("Content snapshots retain message identities, fields and order", arguments: [false, true])
    func contentRetainsMessages(populated: Bool) async {
        let messages: [UIChatMessage] =
            populated
            ? [
                UIChatMessage(id: 7, username: "Zoë 李", message: "👋", date: "09:41"),
                UIChatMessage(id: 12, username: "Zoë 李", message: "👋", date: "09:41"),
                UIChatMessage(id: 21, username: "", message: "", date: ""),
            ] : []
        let original = ChatPanelState(messages: messages)
        let store = ChatStateStore(ChatPanelViewState.content(original))

        let transferred = await Task.detached { await store.snapshot() }.value

        guard case .content(let received) = transferred else {
            Issue.record("A content snapshot must retain its state case")
            return
        }
        #expect(received.messages.count == messages.count)
        #expect(received.messages.map(\.id) == messages.map(\.id))
        for (message, expected) in zip(received.messages, messages) {
            #expect(message.username == expected.username)
            #expect(message.message == expected.message)
            #expect(message.date == expected.date)
        }
    }

    @Test("Loading stays loading across an actor and detached task")
    func loadingRemainsLoading() async {
        let store = ChatStateStore(ChatPanelViewState.loading)
        let received = await Task.detached { await store.snapshot() }.value
        #expect(received == .loading)
    }

    @Test("The initial panel snapshot remains empty after transfer")
    func initialSnapshotRemainsEmpty() async {
        let store = ChatStateStore(ChatPanelState.initial)
        let received = await Task.detached { await store.snapshot() }.value
        #expect(received.messages.isEmpty)
    }
}

private actor ChatStateStore<Value: Sendable> {
    private let value: Value

    init(_ value: Value) { self.value = value }
    func snapshot() -> Value { value }
}
