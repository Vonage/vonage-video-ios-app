import Foundation
import VERADomain

/// Stores mapped value state only; SDK references are never stored or forwarded to the UI.
/// The lock protects aggregation, source registration and the single pending UI snapshot.
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
    private var pendingSnapshot: NetworkMediaStats?
    private var pendingRetries = Set<String>()
    private var scheduled = false
    @MainActor private var handler: ((NetworkMediaStats, Set<String>) -> Void)?

    @MainActor init() {}

    @MainActor func setHandler(_ handler: @escaping (NetworkMediaStats, Set<String>) -> Void) {
        self.handler = handler
    }

    func registerPublisher(_ id: ObjectIdentifier) {
        lock.lock()
        sources = sources.filter {
            if case .publisher = $0.value, $0.key != id {
                retiredSources.insert($0.key)
                return false
            }
            return true
        }
        retiredSources.remove(id)
        sources[id] = .publisher
        lock.unlock()
    }

    func registerSubscriber(_ id: ObjectIdentifier, connectionId: String) {
        lock.lock()
        retiredSources.remove(id)
        sources[id] = .subscriber(connectionId)
        removedConnections.remove(connectionId)
        lock.unlock()
    }

    func update(
        source: ObjectIdentifier,
        connectionId: String? = nil,
        _ operation: (inout NetworkStatsState, inout Set<String>) -> Void
    ) {
        lock.lock()
        guard !retiredSources.contains(source),
            !requiresRegisteredSource || sources[source] != nil,
            connectionId.map({ !removedConnections.contains($0) }) ?? true
        else {
            lock.unlock()
            return
        }
        operation(&state, &pendingRetries)
        pendingSnapshot = state.snapshot
        let shouldSchedule = !scheduled
        scheduled = true
        lock.unlock()
        if shouldSchedule { schedule() }
    }

    func reset() {
        lock.lock()
        state.reset()
        sources.removeAll()
        retiredSources.removeAll()
        requiresRegisteredSource = true
        removedConnections.removeAll()
        pendingRetries.removeAll()
        pendingSnapshot = .empty
        let shouldSchedule = !scheduled
        scheduled = true
        lock.unlock()
        if shouldSchedule { schedule() }
    }

    func removeSubscriber(connectionId: String) {
        lock.lock()
        state.removeSubscriber(connectionId: connectionId)
        removedConnections.insert(connectionId)
        sources = sources.filter {
            if case .subscriber(let id) = $0.value, id == connectionId {
                retiredSources.insert($0.key)
                return false
            }
            return true
        }
        pendingRetries.remove(connectionId)
        pendingSnapshot = state.snapshot
        let shouldSchedule = !scheduled
        scheduled = true
        lock.unlock()
        if shouldSchedule { schedule() }
    }

    private func schedule() {
        if Thread.isMainThread {
            MainActor.assumeIsolated { drain() }
        } else {
            DispatchQueue.main.async { self.drain() }
        }
    }

    @MainActor private func drain() {
        // Bound synchronous publication under sustained SDK load, yielding between batches.
        for _ in 0..<64 {
            lock.lock()
            guard let snapshot = pendingSnapshot else {
                scheduled = false
                lock.unlock()
                return
            }
            let retries = pendingRetries
            pendingSnapshot = nil
            pendingRetries.removeAll()
            lock.unlock()
            handler?(snapshot, retries)
        }
        DispatchQueue.main.async { self.drain() }
    }
}
