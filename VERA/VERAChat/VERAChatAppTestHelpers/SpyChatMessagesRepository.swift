//
//  Created by Vonage on 14/10/25.
//

import Combine
import Foundation
import VERAChat

public class SpyChatMessagesRepository: ChatMessagesRepository {
    public let subject = CurrentValueSubject<[VERAChat.ChatMessage], Never>([])

    public func observeMessages() -> AnyPublisher<[VERAChat.ChatMessage], Never> {
        subject.eraseToAnyPublisher()
    }

    public var onSendMessage: ((String) -> Void)?

    public init(onSendMessage: ((String) -> Void)? = nil) {
        self.onSendMessage = onSendMessage
    }

    public func addMessage(_ message: VERAChat.ChatMessage) {
        subject.value = subject.value + [message]
    }

    public func clearMessages() {
        subject.value = []
    }
}
