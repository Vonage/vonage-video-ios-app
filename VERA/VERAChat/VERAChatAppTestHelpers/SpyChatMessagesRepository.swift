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

    public init() {
    }

    public func addMessage(_ message: VERAChat.ChatMessage) {
        subject.value = subject.value + [message]
    }

    public func clearMessages() {
        subject.value = []
    }
}
