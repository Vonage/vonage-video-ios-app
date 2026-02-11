//
//  DefaultReactionsRepository.swift
//  VERAReactions
//

import Combine
import Foundation

/// Default in-memory implementation of ReactionsRepository.
///
/// Stores reactions in memory and emits them via Combine publishers.
/// Thread-safe for concurrent access.
public final class DefaultReactionsRepository: ReactionsRepository {

    // MARK: - Private Properties

    private let reactionSubject = PassthroughSubject<EmojiReaction, Never>()
    private var storedReactions: [EmojiReaction] = []
    private let lock = NSLock()

    // MARK: - ReactionsObserver

    public var reactionReceived: AnyPublisher<EmojiReaction, Never> {
        reactionSubject.eraseToAnyPublisher()
    }

    public var reactions: [EmojiReaction] {
        lock.lock()
        defer { lock.unlock() }
        return storedReactions
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - ReactionsWriter

    public func addReaction(_ reaction: EmojiReaction) {
        lock.lock()
        storedReactions.append(reaction)
        lock.unlock()
        reactionSubject.send(reaction)
    }

    public func clear() {
        lock.lock()
        storedReactions.removeAll()
        lock.unlock()
    }
}
