//
//  Created by Vonage on 10/10/25.
//

import Combine
import Foundation

public protocol ChatMessagesSender: AnyObject {
    var onSendMessage: ((String) -> Void)? { get set }
}

public protocol ChatMessagesWriter {
    func addMessage(_ message: ChatMessage)
    func clearMessages()
}

public protocol ChatMessagesObserver {
    func observeMessages() -> AnyPublisher<[ChatMessage], Never>
}

public typealias ChatMessagesRepository =
    ChatMessagesWriter & ChatMessagesObserver & ChatMessagesSender
