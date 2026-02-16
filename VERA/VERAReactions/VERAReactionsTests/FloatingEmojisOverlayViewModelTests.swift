//
//  Created by Vonage on 14/2/26.
//

import Combine
import Foundation
import Testing

@testable import VERAReactions

@Suite("FloatingEmojisOverlayViewModel Tests")
struct FloatingEmojisOverlayViewModelTests {

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with empty floating emojis")
    func initializesWithEmptyEmojis() {
        let sut = makeSUT()

        #expect(sut.viewModel.floatingEmojis.isEmpty)
    }

    // MARK: - Reaction Received Tests

    @Test("Adds floating emoji when reaction is received")
    func addsFloatingEmojiOnReaction() async throws {
        let sut = makeSUT()
        let reaction = EmojiReaction(participantName: "Alice", emoji: "🎉")

        await sut.repository.addReaction(reaction)

        try await waitUntil { sut.viewModel.floatingEmojis.count == 1 }

        #expect(sut.viewModel.floatingEmojis.first?.emoji == "🎉")
    }

    @Test("Adds multiple floating emojis for multiple reactions")
    func addsMultipleFloatingEmojis() async throws {
        let sut = makeSUT()

        await sut.repository.addReaction(EmojiReaction(participantName: "Alice", emoji: "🎉"))
        await sut.repository.addReaction(EmojiReaction(participantName: "Bob", emoji: "👍"))

        try await waitUntil { sut.viewModel.floatingEmojis.count == 2 }
    }

    @Test("Floating emoji has valid horizontal position between 0.15 and 0.85")
    func floatingEmojiHasValidHorizontalPosition() async throws {
        let sut = makeSUT()
        let reaction = EmojiReaction(participantName: "Alice", emoji: "❤️")

        await sut.repository.addReaction(reaction)

        try await waitUntil { !sut.viewModel.floatingEmojis.isEmpty }

        let position = try #require(sut.viewModel.floatingEmojis.first?.horizontalPosition)
        #expect(position >= 0.15)
        #expect(position <= 0.85)
    }

    // MARK: - FloatingEmoji Identity Tests

    @Test("FloatingEmoji preserves reaction id")
    func floatingEmojiPreservesReactionId() {
        let id = UUID()
        let reaction = EmojiReaction(id: id, participantName: "Alice", emoji: "👍")
        let floatingEmoji = UIFloatingEmoji(reaction: reaction)

        #expect(floatingEmoji.id == id)
    }

    // MARK: - Field Mapping Tests

    @Test("FloatingEmoji preserves participantName from reaction")
    func floatingEmojiPreservesParticipantName() async throws {
        let sut = makeSUT()

        await sut.repository.addReaction(EmojiReaction(participantName: "Charlie", emoji: "🎉"))

        try await waitUntil { !sut.viewModel.floatingEmojis.isEmpty }

        #expect(sut.viewModel.floatingEmojis.first?.participantName == "Charlie")
    }

    @Test("FloatingEmoji preserves isMe flag from reaction")
    func floatingEmojiPreservesIsMe() async throws {
        let sut = makeSUT()

        await sut.repository.addReaction(EmojiReaction(participantName: "Me", emoji: "👍", isMe: true))

        try await waitUntil { !sut.viewModel.floatingEmojis.isEmpty }

        #expect(sut.viewModel.floatingEmojis.first?.isMe == true)
    }

    @Test("FloatingEmoji preserves isMe as false for remote user")
    func floatingEmojiPreservesIsMeFalse() async throws {
        let sut = makeSUT()

        await sut.repository.addReaction(EmojiReaction(participantName: "Alice", emoji: "❤️", isMe: false))

        try await waitUntil { !sut.viewModel.floatingEmojis.isEmpty }

        #expect(sut.viewModel.floatingEmojis.first?.isMe == false)
    }

    @Test("FloatingEmoji preserves distinct emoji strings")
    func floatingEmojiPreservesDistinctEmojis() async throws {
        let sut = makeSUT()
        let emojis = ["🎉", "👍", "❤️", "😂", "🔥"]

        for emoji in emojis {
            await sut.repository.addReaction(EmojiReaction(participantName: "Alice", emoji: emoji))
        }

        try await waitUntil { sut.viewModel.floatingEmojis.count == emojis.count }

        let resultEmojis = sut.viewModel.floatingEmojis.map(\.emoji)
        #expect(resultEmojis == emojis)
    }

    @Test("FloatingEmoji sets createdAt to approximately now")
    func floatingEmojiSetsCreatedAt() {
        let before = Date()
        let reaction = EmojiReaction(participantName: "Alice", emoji: "🎉")
        let floatingEmoji = UIFloatingEmoji(reaction: reaction)
        let after = Date()

        #expect(floatingEmoji.createdAt >= before)
        #expect(floatingEmoji.createdAt <= after)
    }

    // MARK: - Max Visible Emojis Tests

    @Test("Caps visible emojis at 15 when more reactions arrive")
    func capsAtMaxVisibleEmojis() async throws {
        let sut = makeSUT()

        for i in 0..<16 {
            await sut.repository.addReaction(EmojiReaction(participantName: "User\(i)", emoji: "🎉"))
        }

        try await waitUntil { sut.viewModel.floatingEmojis.count == 15 }
    }

    @Test("Evicts oldest emoji when max visible cap is exceeded")
    func evictsOldestEmojiAtCap() async throws {
        let sut = makeSUT()
        let firstId = UUID()

        await sut.repository.addReaction(EmojiReaction(id: firstId, participantName: "First", emoji: "🎉"))
        for i in 1..<16 {
            await sut.repository.addReaction(EmojiReaction(participantName: "User\(i)", emoji: "👍"))
        }

        try await waitUntil { sut.viewModel.floatingEmojis.count == 15 }

        let ids = sut.viewModel.floatingEmojis.map(\.id)
        #expect(!ids.contains(firstId))
    }

    @Test("Keeps newest emoji when max visible cap is exceeded")
    func keepsNewestEmojiAtCap() async throws {
        let sut = makeSUT()
        let lastId = UUID()

        for i in 0..<15 {
            await sut.repository.addReaction(EmojiReaction(participantName: "User\(i)", emoji: "🎉"))
        }
        await sut.repository.addReaction(EmojiReaction(id: lastId, participantName: "Last", emoji: "🔥"))

        try await waitUntil { sut.viewModel.floatingEmojis.count == 15 }

        let ids = sut.viewModel.floatingEmojis.map(\.id)
        #expect(ids.contains(lastId))
        #expect(sut.viewModel.floatingEmojis.last?.emoji == "🔥")
    }

    // MARK: - Test Helpers

    private struct SUTResult {
        let viewModel: FloatingEmojisOverlayViewModel
        let repository: MockFloatingReactionsRepository
    }

    private func makeSUT() -> SUTResult {
        let repository = MockFloatingReactionsRepository()
        let viewModel = FloatingEmojisOverlayViewModel(reactionsRepository: repository)
        return SUTResult(viewModel: viewModel, repository: repository)
    }

    /// Polls `condition` every 10 ms, throwing if it hasn't become `true`
    /// within `timeout` seconds.
    private func waitUntil(
        timeout: TimeInterval = 0.5,
        _ condition: @escaping @Sendable () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                throw WaitTimeoutError()
            }
            try await Task.sleep(nanoseconds: 10_000_000)  // 10 ms
        }
    }

    private struct WaitTimeoutError: Error, CustomStringConvertible {
        var description: String { "waitUntil timed out" }
    }
}

// MARK: - Mock

private final class MockFloatingReactionsRepository: ReactionsRepository, @unchecked Sendable {
    private let subject = PassthroughSubject<EmojiReaction, Never>()

    var reactionReceived: AnyPublisher<EmojiReaction, Never> {
        subject.eraseToAnyPublisher()
    }

    func addReaction(_ reaction: EmojiReaction) async {
        subject.send(reaction)
    }
}
