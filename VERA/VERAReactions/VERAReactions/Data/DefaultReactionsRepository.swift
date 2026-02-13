//
//  Created by Vonage on 11/2/26.
//

import Combine
import Foundation

/// Default in-memory implementation of ReactionsRepository.
///
/// Stores reactions in memory and emits them via Combine publishers.
/// Uses Swift Actor for thread-safe concurrent access.
public actor DefaultReactionsRepository: ReactionsRepository {

    // MARK: - Private Properties

    private nonisolated let reactionSubject = PassthroughSubject<EmojiReaction, Never>()
    private var storedReactions: [EmojiReaction] = []

    // MARK: - ReactionsObserver

    public nonisolated var reactionReceived: AnyPublisher<EmojiReaction, Never> {
        reactionSubject.eraseToAnyPublisher()
    }

    public var reactions: [EmojiReaction] {
        storedReactions
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - ReactionsWriter

    public func addReaction(_ reaction: EmojiReaction) {
        storedReactions.append(reaction)
        reactionSubject.send(reaction)
    }

    public func clear() {
        storedReactions.removeAll()
    }
}
