//
//  Created by Vonage on 11/2/26.
//

import Combine
import Testing
import VERAReactions
import VERAVonage

@testable import VERAVonageReactionsPlugin

@Suite("VonageReactionsPlugin Tests")
struct VonageReactionsPluginTests {

    // MARK: - Send Reaction Tests

    @Test("sendReaction throws when channel is nil")
    func sendReactionThrowsWhenChannelMissing() async throws {
        let sut = VonageReactionsPlugin()
        let emoji = UIEmojiReaction(emoji: "👍", name: "thumbs up")

        #expect(throws: VonageReactionsPlugin.Error.missingChannel) {
            try sut.sendReaction(emoji.emoji)
        }
    }

    @Test("sendReaction emits signal with correct type and payload")
    func sendReactionEmitsCorrectSignal() async throws {
        let mockChannel = MockSignalChannel()
        let sut = VonageReactionsPlugin()
        sut.channel = mockChannel

        try await sut.callDidStart([VonageCallParams.username.rawValue: "TestUser"])

        let emoji = UIEmojiReaction(emoji: "🎉", name: "party")
        try sut.sendReaction(emoji.emoji)

        #expect(mockChannel.emittedSignals.count == 1)
        #expect(mockChannel.emittedSignals.first?.type == "emoji")

        let payload = mockChannel.emittedSignals.first?.payload ?? ""
        #expect(payload.contains("🎉"))
        #expect(payload.contains("TestUser"))
    }

    // MARK: - Handle Signal Tests

    @Test("handleSignal ignores non-reaction signals")
    func handleSignalIgnoresOtherTypes() {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)

        let signal = VonageSignal(type: "chat", data: "{}")
        sut.handleSignal(signal)

        #expect(repository.addedReactions.isEmpty)
    }

    @Test("handleSignal adds reaction to repository")
    func handleSignalAddsReaction() {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)

        let payload = """
            {"participantName":"Alice","emoji":"👋","timestamp":"2026-02-10T12:00:00Z"}
            """
        let signal = VonageSignal(type: "emoji", data: payload)
        sut.handleSignal(signal)

        #expect(repository.addedReactions.count == 1)
        #expect(repository.addedReactions.first?.emoji == "👋")
        #expect(repository.addedReactions.first?.participantName == "Alice")
    }

    @Test("handleSignal ignores signals with missing data")
    func handleSignalIgnoresMissingData() {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)

        let signal = VonageSignal(type: "emoji", data: nil)
        sut.handleSignal(signal)

        #expect(repository.addedReactions.isEmpty)
    }

    @Test("handleSignal ignores signals with invalid JSON")
    func handleSignalIgnoresInvalidJSON() {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)

        let signal = VonageSignal(type: "emoji", data: "not valid json")
        sut.handleSignal(signal)

        #expect(repository.addedReactions.isEmpty)
    }

    // MARK: - Lifecycle Tests

    @Test("callDidStart extracts username from userInfo")
    func callDidStartExtractsUsername() async throws {
        let mockChannel = MockSignalChannel()
        let sut = VonageReactionsPlugin()
        sut.channel = mockChannel

        try await sut.callDidStart([VonageCallParams.username.rawValue: "JohnDoe"])

        let emoji = UIEmojiReaction(emoji: "👍", name: "thumbs up")
        try sut.sendReaction(emoji.emoji)

        let payload = mockChannel.emittedSignals.first?.payload ?? ""
        #expect(payload.contains("JohnDoe"))
    }

    @Test("callDidEnd clears repository")
    func callDidEndClearsRepository() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)

        await repository.addReaction(EmojiReaction(participantName: "Test", emoji: "👍"))
        #expect(repository.addedReactions.count == 1)

        try await sut.callDidEnd()

        // Allow Task in cleanUp to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(repository.clearCalled)
    }

    // MARK: - Plugin Identifier

    @Test("pluginIdentifier returns correct value")
    func pluginIdentifierReturnsCorrectValue() {
        let sut = VonageReactionsPlugin()
        #expect(sut.pluginIdentifier == "VonageReactionsPlugin")
    }
}

// MARK: - Mocks

final class MockSignalChannel: VonageSignalChannel {
    var emittedSignals: [OutgoingSignal] = []

    func emitSignal(_ signal: OutgoingSignal) throws {
        emittedSignals.append(signal)
    }
}

final class MockReactionsRepository: ReactionsRepository, @unchecked Sendable {
    var addedReactions: [EmojiReaction] = []
    var clearCalled = false

    private let subject = PassthroughSubject<EmojiReaction, Never>()

    var reactionReceived: AnyPublisher<EmojiReaction, Never> {
        subject.eraseToAnyPublisher()
    }

    var reactions: [EmojiReaction] {
        get async { addedReactions }
    }

    func addReaction(_ reaction: EmojiReaction) async {
        addedReactions.append(reaction)
        subject.send(reaction)
    }

    func clear() async {
        clearCalled = true
        addedReactions.removeAll()
    }
}
