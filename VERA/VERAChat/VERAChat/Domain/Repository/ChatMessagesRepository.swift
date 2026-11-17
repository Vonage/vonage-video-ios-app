//
//  Created by Vonage on 10/10/25.
//

import Combine
import Foundation

@MainActor
public protocol ChatMessagesWriter {
    func addMessage(_ message: ChatMessage)
    func clearMessages()
}

@MainActor
public protocol ChatMessagesObserver {
    func observeMessages() -> AnyPublisher<[ChatMessage], Never>
}

public typealias ChatMessagesRepository = ChatMessagesWriter & ChatMessagesObserver
