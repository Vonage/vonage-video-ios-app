//
//  EmojiPickerComponentViewModelTests.swift
//  VERAReactionsTests
//

import Testing
@testable import VERAReactions

// MARK: - Tests

@Suite("EmojiPickerComponentViewModel Tests")
struct EmojiPickerComponentViewModelTests {

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default emojis")
    func initializesWithDefaultEmojis() {
        let mockUseCase = MockSendReactionUseCase()
        let viewModel = EmojiPickerComponentViewModel(sendReactionUseCase: mockUseCase)

        #expect(viewModel.configuration == EmojiPickerConfiguration.default)
        #expect(viewModel.isSending == false)
        #expect(viewModel.lastError == nil)
    }

    @Test("ViewModel initializes with custom emojis")
    func initializesWithCustomEmojis() {
        let customEmojis = [
            UIEmojiReaction(emoji: "🎉", name: "Party"),
            UIEmojiReaction(emoji: "🔥", name: "Fire")
        ]
        let mockUseCase = MockSendReactionUseCase()
        let viewModel = EmojiPickerComponentViewModel(
            configuration: .init(emojis: customEmojis),
            sendReactionUseCase: mockUseCase
        )

        #expect(viewModel.configuration.emojis == customEmojis)
    }

    // MARK: - Send Reaction Tests

    @Test("sendReaction calls use case with emoji string")
    func sendReactionCallsUseCase() {
        let mockUseCase = MockSendReactionUseCase()
        let viewModel = EmojiPickerComponentViewModel(sendReactionUseCase: mockUseCase)
        let emoji = UIEmojiReaction(emoji: "👍", name: "Thumbs Up")

        viewModel.sendReaction(emoji)

        #expect(mockUseCase.sentEmojis == ["👍"])
        #expect(mockUseCase.callCount == 1)
    }

    @Test("sendReaction calls onDismiss after sending")
    func sendReactionCallsOnDismiss() {
        let mockUseCase = MockSendReactionUseCase()
        var dismissCalled = false
        let viewModel = EmojiPickerComponentViewModel(
            sendReactionUseCase: mockUseCase,
            onDismiss: { dismissCalled = true }
        )
        let emoji = UIEmojiReaction(emoji: "❤️", name: "Heart")

        viewModel.sendReaction(emoji)

        #expect(dismissCalled == true)
    }

    @Test("sendReaction handles use case error")
    func sendReactionHandlesError() {
        let mockUseCase = MockSendReactionUseCase(shouldThrow: true)
        var dismissCalled = false
        let viewModel = EmojiPickerComponentViewModel(
            sendReactionUseCase: mockUseCase,
            onDismiss: { dismissCalled = true }
        )
        let emoji = UIEmojiReaction(emoji: "👍", name: "Thumbs Up")

        viewModel.sendReaction(emoji)

        #expect(viewModel.lastError != nil)
        #expect(dismissCalled == false)
    }

    @Test("sendReaction resets error on new send")
    func sendReactionResetsError() {
        let mockUseCase = MockSendReactionUseCase(shouldThrow: true)
        let viewModel = EmojiPickerComponentViewModel(sendReactionUseCase: mockUseCase)
        let emoji = UIEmojiReaction(emoji: "👍", name: "Thumbs Up")

        // First send - should fail
        viewModel.sendReaction(emoji)
        #expect(viewModel.lastError != nil)

        // Configure to succeed
        mockUseCase.shouldThrow = false

        // Second send - error should be reset
        viewModel.sendReaction(emoji)
        #expect(viewModel.lastError == nil)
    }

    // MARK: - Dismiss Tests

    @Test("dismiss calls onDismiss callback")
    func dismissCallsOnDismiss() {
        let mockUseCase = MockSendReactionUseCase()
        var dismissCalled = false
        let viewModel = EmojiPickerComponentViewModel(
            sendReactionUseCase: mockUseCase,
            onDismiss: { dismissCalled = true }
        )

        viewModel.dismiss()

        #expect(dismissCalled == true)
        #expect(mockUseCase.callCount == 0) // Should not send any reaction
    }

    @Test("dismiss without callback does not crash")
    func dismissWithoutCallbackDoesNotCrash() {
        let mockUseCase = MockSendReactionUseCase()
        let viewModel = EmojiPickerComponentViewModel(sendReactionUseCase: mockUseCase)

        // Should not crash
        viewModel.dismiss()
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
