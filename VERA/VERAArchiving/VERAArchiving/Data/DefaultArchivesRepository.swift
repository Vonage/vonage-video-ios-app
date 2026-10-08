//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation
import VERADomain

public final class DefaultArchivesRepository: ArchivesRepository {
    private let archivesDataSource: ArchivesDataSource
    private let pollingInterval: TimeInterval
    private let state = State()

    /// State and task identity are protected together; subscriber callbacks never run under the lock.
    private final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var cache: [String: CurrentValueSubject<[Archive], Error>] = [:]
        private var observers: [String: Set<UUID>] = [:]
        private var pollingTasks: [String: (id: UUID, task: Task<Void, Never>)] = [:]

        func beginObservation(_ id: UUID, for key: String) -> CurrentValueSubject<[Archive], Error> {
            lock.lock()
            defer { lock.unlock() }
            observers[key, default: []].insert(id)
            if let publisher = cache[key] { return publisher }
            let publisher = CurrentValueSubject<[Archive], Error>([])
            cache[key] = publisher
            return publisher
        }

        func endObservation(_ id: UUID, for key: String) {
            lock.lock()
            guard observers[key]?.remove(id) != nil else {
                lock.unlock()
                return
            }
            guard observers[key]?.isEmpty == true else {
                lock.unlock()
                return
            }
            observers.removeValue(forKey: key)
            cache.removeValue(forKey: key)
            let task = pollingTasks.removeValue(forKey: key)?.task
            lock.unlock()
            task?.cancel()
        }

        func startTaskIfNeeded(for key: String, create: (UUID) -> Task<Void, Never>) {
            lock.lock()
            defer { lock.unlock() }
            guard pollingTasks[key] == nil, observers[key]?.isEmpty == false else { return }
            let id = UUID()
            // The task checks its identity under this lock before doing work. Register it first.
            pollingTasks[key] = (id, create(id))
        }

        func isCurrent(_ id: UUID, for key: String) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            return pollingTasks[key]?.id == id
        }

        func finishTask(_ id: UUID, for key: String, evictPublisher: Bool = false) {
            lock.lock()
            defer { lock.unlock() }
            guard pollingTasks[key]?.id == id else { return }
            pollingTasks.removeValue(forKey: key)
            if evictPublisher { cache.removeValue(forKey: key) }
        }

        func cancelAllTasks() {
            lock.lock()
            let tasks = pollingTasks.values.map(\.task)
            let publishers = Array(cache.values)
            pollingTasks.removeAll()
            cache.removeAll()
            observers.removeAll()
            lock.unlock()
            tasks.forEach { $0.cancel() }
            publishers.forEach { $0.send(completion: .finished) }
        }
    }

    public init(
        pollingIntervalSeconds: TimeInterval = 5.0,
        archivesDataSource: ArchivesDataSource
    ) {
        self.pollingInterval = pollingIntervalSeconds
        self.archivesDataSource = archivesDataSource
    }

    deinit { state.cancelAllTasks() }

    public func getArchives(sessionKey: String) async -> AnyPublisher<[Archive], Error> {
        // Resolve the cached subject per subscription. A failed subject must never poison a retry,
        // including a second subscription to the same returned publisher.
        Deferred { [weak self] () -> AnyPublisher<[Archive], Error> in
            guard let self else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
            let observerID = UUID()
            let publisher = self.state.beginObservation(observerID, for: sessionKey)
            self.startPolling(for: sessionKey, publisher: publisher)
            return publisher.handleEvents(
                receiveCompletion: { [state = self.state] _ in
                    state.endObservation(observerID, for: sessionKey)
                },
                receiveCancel: { [state = self.state] in
                    state.endObservation(observerID, for: sessionKey)
                }
            ).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }

    private func startPolling(for sessionKey: String, publisher: CurrentValueSubject<[Archive], Error>) {
        state.startTaskIfNeeded(for: sessionKey) { id in
            Task { [state, archivesDataSource, pollingInterval] in
                defer { state.finishTask(id, for: sessionKey) }
                while !Task.isCancelled, state.isCurrent(id, for: sessionKey) {
                    do {
                        let archives = try await archivesDataSource.getArchives(sessionKey: sessionKey)
                        guard !Task.isCancelled, state.isCurrent(id, for: sessionKey) else { return }
                        publisher.send(archives)
                        if Self.shouldStopPolling(archives) { return }
                        try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                    } catch {
                        guard !Task.isCancelled, state.isCurrent(id, for: sessionKey) else { return }
                        // Release the task and failed cache before completion callbacks can retry.
                        state.finishTask(id, for: sessionKey, evictPublisher: true)
                        publisher.send(completion: .failure(error))
                        return
                    }
                }
            }
        }
    }

    private static func shouldStopPolling(_ archives: [Archive]) -> Bool {
        guard !archives.isEmpty else { return true }
        if archives.contains(where: { $0.status == .failed }) { return true }
        return archives.allSatisfy { $0.status == .available }
    }
}
