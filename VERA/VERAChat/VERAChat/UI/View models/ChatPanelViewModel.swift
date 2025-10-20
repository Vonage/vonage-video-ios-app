//
//  Created by Vonage on 10/10/25.
//

import Combine
import Foundation

public struct ChatPanelState: Equatable {
    public let messages: [UIChatMessage]

    public static let `default` = ChatPanelState(messages: [])

    public init(messages: [UIChatMessage] = []) {
        self.messages = messages
    }
}

public enum ChatPannelViewState: Equatable {
    case content(ChatPanelState)
    case loading
}

public final class ChatPanelViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published public var state: ChatPannelViewState = .loading

    private let chatMessagesRepository: ChatMessagesRepository
    private let sendChatMessageUseCase: SendChatMessageUseCase
    private var isInitialised = false

    public init(
        chatMessagesRepository: ChatMessagesRepository,
        sendChatMessageUseCase: SendChatMessageUseCase
    ) {
        self.chatMessagesRepository = chatMessagesRepository
        self.sendChatMessageUseCase = sendChatMessageUseCase
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

    public func sendMessage(_ message: String) {
        do {
            try sendChatMessageUseCase(message)
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension ChatMessage {
    public var toUIChatMessage: UIChatMessage {
        UIChatMessage(
            id: hashValue,
            username: username,
            message: message,
            date: UIChatMessage.formattedDate(date))
    }
}
