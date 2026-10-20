import Foundation

/// Transfers value events from SDK callback threads to one ordered UI drain.
///
/// The lock protects only the pending buffer and scheduling state. Handlers always execute
/// outside the lock on MainActor, so reentrant callbacks cannot deadlock. Ordered control
/// events are delivered in batches of at most 64, yielding between batches.
final class MainActorEventQueue<Event: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: [Event] = []
    private var scheduled = false
    private var acceptingEvents = true
    @MainActor private var handler: (@MainActor (Event) -> Void)?
    @MainActor private var generation: UInt64 = 0

    @MainActor init() {}

    @MainActor func setHandler(_ handler: @escaping @MainActor (Event) -> Void) {
        self.handler = handler
    }

    /// Explicit setup starts a fresh delivery lifetime, discarding callbacks from the old one.
    @MainActor func activate(_ handler: @escaping @MainActor (Event) -> Void) {
        invalidate()
        self.handler = handler
        lock.lock()
        acceptingEvents = true
        lock.unlock()
    }

    func send(_ event: Event) {
        lock.lock()
        guard acceptingEvents else {
            lock.unlock()
            return
        }
        pending.append(event)
        let shouldSchedule = !scheduled
        scheduled = true
        lock.unlock()
        guard shouldSchedule else { return }
        if Thread.isMainThread {
            MainActor.assumeIsolated { drain() }
        } else {
            DispatchQueue.main.async { self.drain() }
        }
    }

    @MainActor func invalidate() {
        generation &+= 1
        lock.lock()
        acceptingEvents = false
        pending.removeAll()
        lock.unlock()
        handler = nil
    }

    @MainActor private func drain() {
        // A bounded batch yields to other UI work even if callback producers stay busy.
        lock.lock()
        let count = min(pending.count, 64)
        let batch = Array(pending.prefix(count))
        pending.removeFirst(count)
        lock.unlock()
        // Cleanup/setup during a handler must not deliver the old batch to the new lifetime.
        let batchGeneration = generation
        for item in batch {
            guard generation == batchGeneration else { break }
            handler?(item)
        }

        lock.lock()
        let hasMore = !pending.isEmpty
        if !hasMore { scheduled = false }
        lock.unlock()
        if hasMore { DispatchQueue.main.async { self.drain() } }
    }
}
