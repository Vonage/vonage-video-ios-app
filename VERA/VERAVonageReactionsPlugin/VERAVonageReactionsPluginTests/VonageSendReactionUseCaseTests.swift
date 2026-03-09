//
//  Created by Vonage on 12/02/2026.
//

import Testing
import VERAReactions
import VERAVonage

@testable import VERAVonageReactionsPlugin

@Suite("VonageSendReactionUseCase Tests")
struct VonageSendReactionUseCaseTests {

    @Test("callAsFunction delegates to plugin")
    func callAsFunctionDelegatesToPlugin() async throws {
        let mockChannel = MockSignalChannel()
        let plugin = VonageReactionsPlugin()
        plugin.channel = mockChannel

        let sut = VonageSendReactionUseCase(plugin: plugin)
        let emoji = UIEmojiReaction(emoji: "🔥", name: "fire")

        try sut(emoji.emoji)

        #expect(mockChannel.emittedSignals.count == 1)
        #expect(mockChannel.emittedSignals.first?.type == "emoji")
    }

    @Test("callAsFunction throws when plugin has no channel")
    func callAsFunctionThrowsWhenNoChannel() {
        let plugin = VonageReactionsPlugin()
        let sut = VonageSendReactionUseCase(plugin: plugin)
        let emoji = UIEmojiReaction(emoji: "👍", name: "thumbs up")

        #expect(throws: VonageReactionsPlugin.Error.missingChannel) {
            try sut(emoji.emoji)
        }
    }
}
