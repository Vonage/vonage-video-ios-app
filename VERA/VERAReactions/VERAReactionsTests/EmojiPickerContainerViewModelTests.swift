//
//  Created by Vonage on 11/2/26.
//

import Testing

@testable import VERAReactions

// MARK: - Tests

@Suite("EmojiPickerContainerViewModel Tests")
struct EmojiPickerContainerViewModelTests {

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default emojis")
    func initializesWithDefaultEmojis() {
        let sut = makeSUT()

        #expect(sut.configuration == EmojiPickerConfiguration.default)
        #expect(sut.isSending == false)
        #expect(sut.lastError == nil)
    }

    @Test("ViewModel initializes with custom emojis")
    func initializesWithCustomEmojis() {
        let customEmojis = [
            UIEmojiReaction(emoji: "🎉", name: "Party"),
            UIEmojiReaction(emoji: "🔥", name: "Fire"),
        ]
        let sut = makeSUT(configuration: .init(emojis: customEmojis))

        #expect(sut.configuration.emojis == customEmojis)
    }

    // MARK: - Send Reaction Tests

    @Test("sendReaction calls use case with emoji string")
    func sendReactionCallsUseCase() {
        let mockUseCase = MockSendReactionUseCase()
        let sut = makeSUT(mockUseCase)
        let emoji = UIEmojiReaction(emoji: "👍", name: "Thumbs Up")

        sut.sendReaction(emoji)

        #expect(mockUseCase.sentEmojis == ["👍"])
        #expect(mockUseCase.callCount == 1)
    }

    @Test("sendReaction sets isVisible to false after sending")
    func sendReactionSetsIsVisibleToFalse() {
        let sut = makeSUT()
        let emoji = UIEmojiReaction(emoji: "❤️", name: "Heart")

        sut.isVisible = true

        sut.sendReaction(emoji)

        #expect(sut.isVisible == false)
    }

    @Test("sendReaction keeps isVisible true on error")
    func sendReactionHandlesError() {
        let mockUsecase = MockSendReactionUseCase(shouldThrow: true)
        let sut = makeSUT(mockUsecase)
        let emoji = UIEmojiReaction(emoji: "👍", name: "Thumbs Up")
        sut.isVisible = true

        sut.sendReaction(emoji)

        #expect(sut.lastError != nil)
        #expect(sut.isVisible == true)
    }

    @Test("sendReaction resets error on new send")
    func sendReactionResetsError() {
        let mockUseCase = MockSendReactionUseCase(shouldThrow: true)
        let sut = makeSUT(mockUseCase)
        let emoji = UIEmojiReaction(emoji: "👍", name: "Thumbs Up")

        // First send - should fail
        sut.sendReaction(emoji)
        #expect(sut.lastError != nil)

        // Configure to succeed
        mockUseCase.shouldThrow = false

        // Second send - error should be reset
        sut.sendReaction(emoji)
        #expect(sut.lastError == nil)
    }

    // MARK: - Dismiss Tests

    @Test("dismiss sets isVisible to false")
    func dismissSetsIsVisibleToFalse() {
        let mockUseCase = MockSendReactionUseCase()
        let sut = makeSUT(mockUseCase)

        sut.isVisible = true

        sut.dismiss()

        #expect(sut.isVisible == false)
        #expect(mockUseCase.callCount == 0)  // Should not send any reaction
    }

    @Test("initial isVisible is false")
    func initialIsVisibleIsFalse() {
        let sut = makeSUT()

        #expect(sut.isVisible == false)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        _ usecase: SendReactionUseCase = MockSendReactionUseCase(shouldThrow: false),
        configuration: EmojiPickerConfiguration = .default
    ) -> EmojiPickerContainerViewModel {
        return .init(configuration: configuration, sendReactionUseCase: usecase)
    }
}

// MARK: - Mock

final class MockSendReactionUseCase: SendReactionUseCase {

    private(set) var sentEmojis: [String] = []
    private(set) var callCount: Int = 0
    var shouldThrow: Bool

    init(shouldThrow: Bool = false) {
        self.shouldThrow = shouldThrow
    }

    func callAsFunction(_ emoji: String) throws {
        callCount += 1
        if shouldThrow {
            throw MockError.sendFailed
        }
        sentEmojis.append(emoji)
    }

    enum MockError: Error {
        case sendFailed
    }
}
