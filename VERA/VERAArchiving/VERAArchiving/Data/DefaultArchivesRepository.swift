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

    /// Owns publisher identity and polling generations under one lock.
    final class State: @unchecked Sendable {
        struct Registration {
            let publisher: CurrentValueSubject<[Archive], Error>
            let generation: UUID
            let previousTask: Task<Void, Never>?
        }

        private struct Polling {
            let generation: UUID
            var task: Task<Void, Never>?
        }

        private let lock = NSLock()
        private var cache: [String: CurrentValueSubject<[Archive], Error>] = [:]
        private var polling: [String: Polling] = [:]

        func beginPolling(for sessionKey: String) -> Registration {
            lock.lock()
            defer { lock.unlock() }
            let publisher = cache[sessionKey] ?? CurrentValueSubject<[Archive], Error>([])
            cache[sessionKey] = publisher
            let generation = UUID()
            let previousTask = polling[sessionKey]?.task
            polling[sessionKey] = Polling(generation: generation)
            return Registration(publisher: publisher, generation: generation, previousTask: previousTask)
        }

        func installTask(_ task: Task<Void, Never>, for sessionKey: String, generation: UUID) {
            let installed = lock.withLock {
                guard polling[sessionKey]?.generation == generation else { return false }
                polling[sessionKey]?.task = task
                return true
            }
            // Cancellation handlers may reenter the repository, so cancel outside the lock.
            if !installed { task.cancel() }
        }

        func isCurrent(for sessionKey: String, generation: UUID) -> Bool {
            lock.withLock { polling[sessionKey]?.generation == generation }
        }

        func finishPolling(for sessionKey: String, generation: UUID) {
            lock.withLock {
                guard polling[sessionKey]?.generation == generation else { return }
                polling.removeValue(forKey: sessionKey)
            }
        }

        func takeFailedPolling(
            for sessionKey: String, generation: UUID,
            publisher: CurrentValueSubject<[Archive], Error>
        ) -> Bool {
            lock.withLock {
                guard polling[sessionKey]?.generation == generation,
                    cache[sessionKey] === publisher
                else { return false }
                polling.removeValue(forKey: sessionKey)
                cache.removeValue(forKey: sessionKey)
                return true
            }
        }
    }

    public init(
        pollingIntervalSeconds: TimeInterval = 5.0,
        archivesDataSource: ArchivesDataSource
    ) {
        self.pollingInterval = pollingIntervalSeconds
        self.archivesDataSource = archivesDataSource
    }

    public func getArchives(
        sessionKey: String
    ) async -> AnyPublisher<[Archive], Error> {
        let registration = state.beginPolling(for: sessionKey)
        registration.previousTask?.cancel()
        startPolling(for: sessionKey, registration: registration)
        return registration.publisher.eraseToAnyPublisher()
    }

    private func startPolling(
        for sessionKey: String,
        registration: State.Registration
    ) {
        let publisher = registration.publisher
        let generation = registration.generation
        let task = Task { [state, archivesDataSource, pollingInterval] in
            repeat {
                guard !Task.isCancelled, state.isCurrent(for: sessionKey, generation: generation) else { return }
                do {
                    let archives = try await archivesDataSource.getArchives(sessionKey: sessionKey)

                    // Check if task was cancelled
                    guard !Task.isCancelled, state.isCurrent(for: sessionKey, generation: generation) else { return }

                    publisher.value = archives

                    // Stop polling once no archive or transcript is still being produced.
                    // A transcript keeps processing after its parent archive is uploaded or available.
                    if !archives.contains(where: \.isPending) {
                        state.finishPolling(for: sessionKey, generation: generation)
                        return
                    }

                    // Wait before next poll
                    try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))

                } catch {
                    guard !Task.isCancelled else { return }
                    // Claim failure and evict atomically before delivering outside the lock.
                    // A superseded task must not complete or remove its replacement's publisher.
                    if state.takeFailedPolling(for: sessionKey, generation: generation, publisher: publisher) {
                        publisher.send(completion: .failure(error))
                    }
                    return
                }
            } while !Task.isCancelled
        }

        state.installTask(task, for: sessionKey, generation: generation)
    }
}
