import Foundation

/// Owns a separate attempt budget and cancellation lifetime for each remote stream.
@MainActor
final class SubscriptionRecovery {
    @MainActor
    private final class Entry {
        let generation = UUID()
        let recovery = VideoRecovery()
        let isAvailable: @MainActor () -> Bool
        let subscribe: @MainActor (UUID) async throws -> Void
        var task: Task<Void, Never>?

        init(isAvailable: @escaping @MainActor () -> Bool, subscribe: @escaping @MainActor (UUID) async throws -> Void)
        {
            self.isAvailable = isAvailable
            self.subscribe = subscribe
        }
    }

    private var entries: [String: Entry] = [:]
    var wait: @MainActor (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    var onError: @MainActor (Error) -> Void = { _ in }

    func add(
        streamID: String,
        isAvailable: @escaping @MainActor () -> Bool,
        subscribe: @escaping @MainActor (UUID) async throws -> Void
    ) {
        guard entries[streamID] == nil else { return }
        let entry = Entry(isAvailable: isAvailable, subscribe: subscribe)
        entry.recovery.wait = wait
        entries[streamID] = entry
        entry.task = Task { [weak self, weak entry] in
            guard let self, let entry else { return }
            await self.attempt(streamID: streamID, entry: entry)
            entry.task = nil
        }
    }

    func isCurrent(streamID: String, generation: UUID) -> Bool {
        entries[streamID]?.generation == generation
    }

    func connected(streamID: String, generation: UUID) {
        guard let entry = entries[streamID], entry.generation == generation else { return }
        entry.recovery.reset()
        entry.recovery.beginAttempt()
    }

    func failed(streamID: String, generation: UUID, error: Error) {
        guard let entry = entries[streamID], entry.generation == generation else { return }
        guard entry.isAvailable(), !(error is CancellationError) else {
            remove(streamID: streamID)
            return
        }
        let scheduled = entry.recovery.schedule(policy: .subscriber, error: error) { [weak self, weak entry] in
            guard let self, let entry else { return }
            await self.attempt(streamID: streamID, entry: entry)
        }
        if !scheduled {
            remove(streamID: streamID)
            onError(error)
        }
    }

    func remove(streamID: String) {
        let entry = entries.removeValue(forKey: streamID)
        entry?.task?.cancel()
        entry?.recovery.cancel()
    }

    func cancelAll() {
        for streamID in Array(entries.keys) { remove(streamID: streamID) }
    }

    private func attempt(streamID: String, entry: Entry) async {
        guard entries[streamID] === entry else { return }
        guard entry.isAvailable(), !Task.isCancelled else {
            remove(streamID: streamID)
            return
        }
        entry.recovery.beginAttempt()
        do {
            try await entry.subscribe(entry.generation)
        } catch {
            failed(streamID: streamID, generation: entry.generation, error: error)
        }
    }
}
