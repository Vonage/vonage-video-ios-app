//
//  Created by Vonage on 10/10/25.
//

import Combine
import Foundation

public protocol ChatMessagesRepository {
    func addMessage(_ message: ChatMessage)
    func observeMessages() -> AnyPublisher<[ChatMessage], Never>
}
