//
//  Created by Vonage on 10/10/25.
//

import Combine
import Foundation

public struct ChatPannelState {
    public let messages: [UIChatMessage]

    public static let `default` = ChatPannelState(messages: [])
}

public enum ChatPannelViewState {
    case content(ChatPannelState)
    case error(String)
    case loading
}

public final class ChatPanelViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published public var state: ChatPannelViewState = .loading

    private let chatMessagesRepository: ChatMessagesRepository
    private var isInitialised = false

    public init(chatMessagesRepository: ChatMessagesRepository) {
        self.chatMessagesRepository = chatMessagesRepository
    }

    public func loadData() {
        guard !isInitialised else { return }
        isInitialised = true

        chatMessagesRepository.observeMessages()
            .map { messages in
                messages.map { $0.toUIChatMessage }
            }
            .sink { [weak self] messages in
                guard let self else { return }
                self.state = .content(.init(messages: messages))
            }
            .store(in: &cancellables)
    }
}

extension ChatMessage {
    var toUIChatMessage: UIChatMessage {
        UIChatMessage(
            username: username,
            message: message,
            date: UIChatMessage.formattedDate(date))
    }
}
