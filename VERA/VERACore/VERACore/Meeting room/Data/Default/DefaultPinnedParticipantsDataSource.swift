//
//  Created by Vonage on 17/3/26.
//

import Combine
import Foundation

/// Thread-safe actor managing pinned participant state.
///
/// Uses a ``CurrentValueSubject`` to expose reactive updates and an actor
/// to serialize all mutations, ensuring atomic read/write access.
public actor DefaultPinnedParticipantsDataSource: PinnedParticipantsDataSource {

    // MARK: - Private Properties

    private nonisolated let pinnedIdsSubject = CurrentValueSubject<Set<String>, Never>([])

    // MARK: - PinnedParticipantsDataSource

    public nonisolated var pinnedParticipantIds: AnyPublisher<Set<String>, Never> {
        pinnedIdsSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Mutations

    public func togglePin(participantId: String) {
        var current = pinnedIdsSubject.value
        if current.contains(participantId) {
            current.remove(participantId)
        } else {
            current.insert(participantId)
        }
        pinnedIdsSubject.send(current)
    }

    public func removeParticipants(notIn activeIds: Set<String>) {
        let filtered = pinnedIdsSubject.value.intersection(activeIds)
        guard filtered != pinnedIdsSubject.value else { return }
        pinnedIdsSubject.send(filtered)
    }

    public func reset() {
        pinnedIdsSubject.send([])
    }
}
