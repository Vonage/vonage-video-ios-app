//
//  Created by Vonage on 26/3/26.
//

import Combine
import Foundation

public final class ChatBadgeButtonViewModel: ObservableObject {

    @Published public private(set) var unreadMessagesCount: Int = 0

    private var cancellables = Set<AnyCancellable>()
    private var totalMessageCount: Int = 0
    private var lastReadCount: Int = 0
    private var isChatVisible: Bool = false

    public init(chatMessagesObserver: ChatMessagesObserver) {
        chatMessagesObserver.observeMessages()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                guard let self else { return }
                self.totalMessageCount = messages.count
                if self.isChatVisible {
                    self.lastReadCount = messages.count
                    self.unreadMessagesCount = 0
                } else {
                    self.unreadMessagesCount = max(0, messages.count - self.lastReadCount)
                }
            }
            .store(in: &cancellables)
    }

    public func chatDidOpen() {
        isChatVisible = true
        lastReadCount = totalMessageCount
        unreadMessagesCount = 0
    }

    public func chatDidClose() {
        isChatVisible = false
    }
}
