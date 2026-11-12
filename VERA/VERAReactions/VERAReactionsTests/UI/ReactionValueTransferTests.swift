//
//  Created by Vonage on 15/10/26.
//

import Foundation
import Testing
import VERAReactions

@Suite("Reaction display snapshot transfers")
struct ReactionValueTransferTests {
    @Test("Picker values retain identity, emoji and direct or localized accessibility names")
    func pickerValuesPreserveNames() async {
        let original = [
            UIEmojiReaction(emoji: "👩🏽‍💻", name: "Développeuse 李"),
            UIEmojiReaction(emoji: "👍", nameKey: "emoji.thumbs_up"),
            UIEmojiReaction(emoji: "", name: ""),
        ]
        let store = ReactionSnapshotStore(original)

        let transferred = await Task.detached { await store.snapshot() }.value

        #expect(transferred.count == original.count)
        for (received, expected) in zip(transferred, original) {
            #expect(received.id == expected.id)
            #expect(received.emoji == expected.emoji)
            #expect(received.name == expected.name)
        }
    }

    @Test("The default picker catalog keeps its existing generated identities and order")
    func defaultPickerCatalogPreservesIdentities() async {
        let original = UIEmojiReaction.defaultEmojis
        let store = ReactionSnapshotStore(original)

        let transferred = await Task.detached { await store.snapshot() }.value

        #expect(!original.isEmpty)
        #expect(transferred == original)
        #expect(transferred.map(\.name) == original.map(\.name))
    }

    @Test("A floating snapshot retains its creation time and randomized placement", arguments: [false, true])
    func floatingSnapshotIsNotRecreated(isMe: Bool) async {
        let reaction = EmojiReaction(participantName: "Zoë 李", emoji: "🎉", isMe: isMe)
        let original = UIFloatingEmoji(reaction: reaction)
        let store = ReactionSnapshotStore(original)

        let transferred = await Task.detached { await store.snapshot() }.value

        #expect(transferred.id == reaction.id)
        #expect(transferred.participantName == reaction.participantName)
        #expect(transferred.emoji == reaction.emoji)
        #expect(transferred.isMe == isMe)
        #expect(transferred.horizontalPosition == original.horizontalPosition)
        #expect((0.15...0.85).contains(transferred.horizontalPosition))
        #expect(transferred.createdAt == original.createdAt)
    }
}

private actor ReactionSnapshotStore<Value: Sendable> {
    private let value: Value

    init(_ value: Value) { self.value = value }
    func snapshot() -> Value { value }
}
