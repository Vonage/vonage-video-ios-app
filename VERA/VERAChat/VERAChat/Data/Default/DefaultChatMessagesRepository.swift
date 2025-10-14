//
//  Created by Vonage on 13/10/25.
//

import Combine
import Foundation

public final class DefaultChatMessagesRepository: ChatMessagesRepository {

    public var onSendMessage: ((String) -> Void)?

    private let _messages = CurrentValueSubject<[ChatMessage], Never>([])
    public lazy var messages: AnyPublisher<[ChatMessage], Never> =
        _messages.eraseToAnyPublisher()

    public init(messages: [ChatMessage] = []) {
        _messages.value = messages
    }

    public func addMessage(_ message: ChatMessage) {
        let storedMessages = _messages.value
        _messages.value = storedMessages + [message]
    }

    public func clearMessages() {
        _messages.value = []
    }

    public func observeMessages() -> AnyPublisher<[ChatMessage], Never> { messages }
}
