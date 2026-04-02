//
//  Created by Vonage on 2/4/26.
//

import Combine
import Foundation
import Testing
import VERAReactions

@Suite("DefaultReactionsRepository tests")
struct DefaultReactionsRepositoryTests {

    @Test("Adding a reaction publishes it to observers")
    func addReactionPublishesToObservers() async {
        let sut = DefaultReactionsRepository()
        var receivedReactions: [EmojiReaction] = []
        let cancellable = sut.reactionReceived.sink { reaction in
            receivedReactions.append(reaction)
        }

        let reaction = EmojiReaction(
            participantName: "Alice",
            emoji: "👍")

        await sut.addReaction(reaction)

        // Give time for the combine pipeline
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedReactions.count == 1)
        #expect(receivedReactions.first?.participantName == "Alice")
        #expect(receivedReactions.first?.emoji == "👍")
        _ = cancellable
    }

    @Test("Multiple reactions are published in order")
    func multipleReactionsPublishedInOrder() async {
        let sut = DefaultReactionsRepository()
        var receivedEmojis: [String] = []
        let cancellable = sut.reactionReceived.sink { reaction in
            receivedEmojis.append(reaction.emoji)
        }

        await sut.addReaction(EmojiReaction(participantName: "A", emoji: "👍"))
        await sut.addReaction(EmojiReaction(participantName: "B", emoji: "❤️"))
        await sut.addReaction(EmojiReaction(participantName: "C", emoji: "🎉"))

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedEmojis == ["👍", "❤️", "🎉"])
        _ = cancellable
    }

    @Test("Reactions are fire-and-forget - no history retained")
    func reactionsAreFireAndForget() async {
        let sut = DefaultReactionsRepository()

        // Add reaction before subscribing
        await sut.addReaction(EmojiReaction(participantName: "A", emoji: "👍"))

        // Now subscribe
        var receivedReactions: [EmojiReaction] = []
        let cancellable = sut.reactionReceived.sink { reaction in
            receivedReactions.append(reaction)
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should not have received the reaction added before subscribing
        #expect(receivedReactions.isEmpty)
        _ = cancellable
    }
}
