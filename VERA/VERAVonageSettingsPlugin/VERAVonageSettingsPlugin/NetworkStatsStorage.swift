import Foundation
import VERADomain

/// Stores mapped value state only; SDK references are never stored or forwarded to the UI.
/// The lock protects aggregation, source registration and the pending UI delivery.
///
/// Snapshots are always delivered asynchronously on the main queue, at most once per main-loop pass,
/// so no mutating method ever runs the handler before it returns.
final class NetworkStatsStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var state = NetworkStatsState()
    private var removedConnections = Set<String>()
    private enum Source {
        case publisher
        case subscriber(String)
    }
    private var sources: [ObjectIdentifier: Source] = [:]
    private var retiredSources = Set<ObjectIdentifier>()
    private var requiresRegisteredSource = false
    /// The state changed since the last delivery; the snapshot is built once, when draining.
    private var hasPendingChanges = false
    private var pendingRetries = Set<String>()
    private var scheduled = false
    @MainActor private var handler: ((NetworkMediaStats, Set<String>) -> Void)?

    @MainActor init() {}

    /// Sets the main-actor handler. Changes recorded before the handler was set are delivered to it.
    @MainActor func setHandler(_ handler: @escaping (NetworkMediaStats, Set<String>) -> Void) {
        self.handler = handler
        scheduleIfPending()
    }

    func registerPublisher(_ id: ObjectIdentifier) {
        lock.withLock {
            for (key, source) in sources where key != id {
                if case .publisher = source {
                    sources[key] = nil
                    retiredSources.insert(key)
                }
            }
            retiredSources.remove(id)
            sources[id] = .publisher
        }
    }

    func registerSubscriber(_ id: ObjectIdentifier, connectionId: String) {
        lock.withLock {
            retiredSources.remove(id)
            sources[id] = .subscriber(connectionId)
            removedConnections.remove(connectionId)
        }
    }

    /// Applies `operation` to the aggregated state if `source` is still current.
    ///
    /// - Important: `operation` runs while the storage lock is held. Map SDK objects and parse
    ///   reports before calling, so the closure only assigns already-mapped values; it must not
    ///   touch SDK objects or call back into this storage (`NSLock` is not re-entrant).
    func update(
        source: ObjectIdentifier,
        connectionId: String? = nil,
        _ operation: (inout NetworkStatsState, inout Set<String>) -> Void
    ) {
        let shouldSchedule: Bool = lock.withLock {
            guard !retiredSources.contains(source),
                !requiresRegisteredSource || sources[source] != nil,
                connectionId.map({ !removedConnections.contains($0) }) ?? true
            else { return false }
            operation(&state, &pendingRetries)
            return markPending()
        }
        if shouldSchedule { schedule() }
    }

    func reset() {
        let shouldSchedule: Bool = lock.withLock {
            state.reset()
            sources.removeAll()
            retiredSources.removeAll()
            requiresRegisteredSource = true
            removedConnections.removeAll()
            pendingRetries.removeAll()
            return markPending()
        }
        if shouldSchedule { schedule() }
    }

    func removeSubscriber(connectionId: String) {
        let shouldSchedule: Bool = lock.withLock {
            state.removeSubscriber(connectionId: connectionId)
            removedConnections.insert(connectionId)
            for (key, source) in sources {
                if case .subscriber(let id) = source, id == connectionId {
                    sources[key] = nil
                    retiredSources.insert(key)
                }
            }
            pendingRetries.remove(connectionId)
            return markPending()
        }
        if shouldSchedule { schedule() }
    }

    /// Records a change; returns `true` when a delivery pass has to be scheduled. Call with the lock held.
    private func markPending() -> Bool {
        hasPendingChanges = true
        guard !scheduled else { return false }
        scheduled = true
        return true
    }

    @MainActor private func scheduleIfPending() {
        let shouldSchedule: Bool = lock.withLock {
            guard hasPendingChanges else { return false }
            return markPending()
        }
        if shouldSchedule { schedule() }
    }

    private func schedule() {
        DispatchQueue.main.async { self.drain() }
    }

    /// Delivers the latest state once. Changes made while the handler runs schedule the next pass.
    @MainActor private func drain() {
        guard let handler else {
            // Keep the pending changes and retries; `setHandler` delivers them.
            lock.withLock { scheduled = false }
            return
        }
        let delivery: (NetworkMediaStats, Set<String>)? = lock.withLock {
            scheduled = false
            guard hasPendingChanges else { return nil }
            hasPendingChanges = false
            let retries = pendingRetries
            pendingRetries.removeAll()
            return (state.snapshot, retries)
        }
        if let (snapshot, retries) = delivery {
            handler(snapshot, retries)
        }
    }
}
