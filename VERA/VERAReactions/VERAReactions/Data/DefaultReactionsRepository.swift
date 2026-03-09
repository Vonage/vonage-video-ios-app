//
//  Created by Vonage on 11/2/26.
//

import Combine
import Foundation

/// Default implementation of ReactionsRepository.
///
/// Relays reactions to observers via a Combine PassthroughSubject.
/// Does not retain history — each reaction is fire-and-forget.
/// Uses Swift Actor for thread-safe concurrent access.
public actor DefaultReactionsRepository: ReactionsRepository {

    // MARK: - Private Properties

    private nonisolated let reactionSubject = PassthroughSubject<EmojiReaction, Never>()

    // MARK: - ReactionsObserver

    public nonisolated var reactionReceived: AnyPublisher<EmojiReaction, Never> {
        reactionSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - ReactionsWriter

    public func addReaction(_ reaction: EmojiReaction) async {
        reactionSubject.send(reaction)
    }
}
