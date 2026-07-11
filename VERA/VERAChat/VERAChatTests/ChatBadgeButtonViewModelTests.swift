//
//  Created by Vonage on 26/3/26.
//

import Combine
import Foundation
import Testing
import VERAChat
import VERAChatAppTestHelpers
import VERACommonUI

@Suite("Chat badge button view model tests")
struct ChatBadgeButtonViewModelTests {

    @Test func initialStateHasZeroUnreadMessages() async {
        let repository = SpyChatMessagesRepository()
        let sut = ChatBadgeButtonViewModel(chatMessagesObserver: repository)

        let count = await sut.$unreadMessagesCount.values.first { _ in true }

        #expect(count == 0)
    }

    @Test func newMessageIncrementsUnreadCount() async {
        let repository = SpyChatMessagesRepository()
        let sut = ChatBadgeButtonViewModel(chatMessagesObserver: repository)

        // Wait for Combine subscription to be established
        _ = await sut.$unreadMessagesCount.values.first { _ in true }

        repository.addMessage(makeMessage("Hello"))

        let count = await sut.$unreadMessagesCount.values.first { $0 > 0 }

        #expect(count == 1)
    }

    @Test func multipleMessagesIncrementUnreadCount() async {
        let repository = SpyChatMessagesRepository()
        let sut = ChatBadgeButtonViewModel(chatMessagesObserver: repository)

        repository.addMessage(makeMessage("Hello"))
        repository.addMessage(makeMessage("World"))
        repository.addMessage(makeMessage("Test"))

        // Give time for the publisher to process on main queue
        try? await Task.sleep(nanoseconds: 100_000_000)

        let count = await MainActor.run { sut.unreadMessagesCount }

        #expect(count == 3)
    }

    @Test func chatDidOpenResetsUnreadCount() async {
        let repository = SpyChatMessagesRepository()
        let sut = ChatBadgeButtonViewModel(chatMessagesObserver: repository)

        repository.addMessage(makeMessage("Hello"))
        repository.addMessage(makeMessage("World"))

        _ = await sut.$unreadMessagesCount.values.first { $0 == 2 }

        await MainActor.run {
            sut.chatDidOpen()
        }

        let count = await sut.$unreadMessagesCount.values.first { _ in true }

        #expect(count == 0)
    }

    @Test func messagesWhileChatIsOpenDoNotIncrementUnreadCount() async {
        let repository = SpyChatMessagesRepository()
        let sut = ChatBadgeButtonViewModel(chatMessagesObserver: repository)

        await MainActor.run {
            sut.chatDidOpen()
        }

        repository.addMessage(makeMessage("Hello"))

        // Give time for the publisher to process
        try? await Task.sleep(nanoseconds: 100_000_000)

        let count = await MainActor.run { sut.unreadMessagesCount }

        #expect(count == 0)
    }

    @Test func messagesAfterChatClosedIncrementUnreadCount() async {
        let repository = SpyChatMessagesRepository()
        let sut = ChatBadgeButtonViewModel(chatMessagesObserver: repository)

        repository.addMessage(makeMessage("Hello"))

        _ = await sut.$unreadMessagesCount.values.first { $0 == 1 }

        await MainActor.run {
            sut.chatDidOpen()
        }

        _ = await sut.$unreadMessagesCount.values.first { $0 == 0 }

        await MainActor.run {
            sut.chatDidClose()
        }

        repository.addMessage(makeMessage("New message"))

        let count = await sut.$unreadMessagesCount.values.first { $0 > 0 }

        #expect(count == 1)
    }

    @Test func bottomItemPresentableExposesMetadataAndAction() async {
        let repository = SpyChatMessagesRepository()
        let sut = ChatBadgeButtonViewModel(chatMessagesObserver: repository)

        repository.addMessage(makeMessage("Hello"))
        _ = await sut.$unreadMessagesCount.values.first { $0 == 1 }

        await MainActor.run {
            #expect(sut.id == "chat-button")
            #expect(sut.label == String(localized: "Chat", bundle: .veraChat))
            #expect(sut.accessibilityIdentifier == nil)
            #expect(sut.isActive == false)
            #expect(sut.accessory?.placement == .topTrailing)
            #expect(sut.accessory?.allowsHitTesting == false)
            _ = sut.accessory?.content()

            sut.performAction()
        }

        let count = await sut.$unreadMessagesCount.values.first { _ in true }

        #expect(count == 0)
    }

    @Test func bottomItemPresentableHasNoAccessoryWithoutUnreadMessages() async {
        let repository = SpyChatMessagesRepository()
        let sut = ChatBadgeButtonViewModel(chatMessagesObserver: repository)

        await MainActor.run {
            #expect(sut.unreadMessagesCount == 0)
            #expect(sut.accessory == nil)
        }
    }

    // MARK: Helpers

    private func makeMessage(_ text: String) -> ChatMessage {
        ChatMessage(
            username: "User",
            message: text,
            date: Date())
    }
}
