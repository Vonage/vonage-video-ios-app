import Foundation

/// Transfers value events from SDK callback threads to one ordered UI drain.
///
/// The lock protects only the pending buffer and scheduling state. Handlers always execute
/// outside the lock on MainActor, so reentrant callbacks cannot deadlock. Audio levels and
/// dimensions may replace their last pending value; control and caption events remain ordered.
final class MainActorEventQueue<Event: Sendable>: @unchecked Sendable {
    typealias DrainOperation = @MainActor @Sendable () -> Void

    private let lock = NSLock()
    /// Schedules a deferred UI drain. Tests control this boundary without blocking MainActor.
    private let scheduleDrain: @Sendable (@escaping DrainOperation) -> Void
    /// Runs under the buffer lock before coalescing. It must be constructed in a nonisolated
    /// context; the plain closure type cannot prove this, so callers use nonisolated factories.
    /// Captured value-processing state belongs exclusively to this queue's lock. The operation
    /// must be short and must never invoke SDK, UI or queue callbacks.
    private let transformEvent: (Event) -> Event
    private var pending: [(key: String?, event: Event)] = []
    private var scheduled = false
    private var acceptingEvents = true
    @MainActor private var handler: (@MainActor (Event) -> Void)?
    @MainActor private var generation: UInt64 = 0

    @MainActor init(
        transformEvent: @escaping (Event) -> Event = { $0 },
        scheduleDrain: @escaping @Sendable (@escaping DrainOperation) -> Void = { operation in
            DispatchQueue.main.async(execute: operation)
        }
    ) {
        self.transformEvent = transformEvent
        self.scheduleDrain = scheduleDrain
    }

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

    func send(_ event: Event, replacing key: String? = nil) {
        lock.lock()
        guard acceptingEvents else {
            lock.unlock()
            return
        }
        let event = transformEvent(event)
        if let key, let index = pending.lastIndex(where: { $0.key == key }) {
            pending[index].event = event
        } else {
            pending.append((key, event))
        }
        let shouldSchedule = !scheduled
        scheduled = true
        lock.unlock()
        guard shouldSchedule else { return }
        if Thread.isMainThread {
            MainActor.assumeIsolated { drain() }
        } else {
            scheduleDrain { self.drain() }
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
            handler?(item.event)
        }

        lock.lock()
        let hasMore = !pending.isEmpty
        if !hasMore { scheduled = false }
        lock.unlock()
        if hasMore { scheduleDrain { self.drain() } }
    }
}
