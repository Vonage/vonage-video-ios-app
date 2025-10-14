//
//  Created by Vonage on 14/10/25.
//

import Combine
import Foundation
import VERAChat
import VERACore

class SpyChatMessagesRepository: ChatMessagesRepository {
    let subject = CurrentValueSubject<[VERAChat.ChatMessage], Never>([])

    func observeMessages() -> AnyPublisher<[VERAChat.ChatMessage], Never> {
        subject.eraseToAnyPublisher()
    }

    var onSendMessage: ((String) -> Void)?

    func addMessage(_ message: VERAChat.ChatMessage) {

    }

    func clearMessages() {

    }
}
