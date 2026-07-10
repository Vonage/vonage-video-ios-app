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

    /// Thread-safe state container for mutable dictionaries.
    private final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var cache: [String: CurrentValueSubject<[Archive], Error>] = [:]
        private var pollingTasks: [String: Task<Void, Never>] = [:]

        func getPublisher(for sessionKey: String) -> CurrentValueSubject<[Archive], Error> {
            lock.lock()
            defer { lock.unlock() }

            if let publisher = cache[sessionKey] {
                return publisher
            }
            let publisher = CurrentValueSubject<[Archive], Error>([])
            cache[sessionKey] = publisher
            return publisher
        }

        func cancelExistingTask(for sessionKey: String) {
            lock.lock()
            defer { lock.unlock() }

            pollingTasks[sessionKey]?.cancel()
        }

        func setTask(_ task: Task<Void, Never>, for sessionKey: String) {
            lock.lock()
            defer { lock.unlock() }

            pollingTasks[sessionKey] = task
        }

        func removeTask(for sessionKey: String) {
            lock.lock()
            defer { lock.unlock() }

            pollingTasks.removeValue(forKey: sessionKey)
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
        let publisher = state.getPublisher(for: sessionKey)

        // Start polling
        startPolling(for: sessionKey, publisher: publisher)

        return publisher.eraseToAnyPublisher()
    }

    private func startPolling(
        for sessionKey: String,
        publisher: CurrentValueSubject<[Archive], Error>
    ) {
        // Cancel any existing polling task for this room
        state.cancelExistingTask(for: sessionKey)

        let task = Task { [state, archivesDataSource, pollingInterval] in
            repeat {
                do {
                    let archives = try await archivesDataSource.getArchives(sessionKey: sessionKey)

                    // Check if task was cancelled
                    guard !Task.isCancelled else { return }

                    publisher.value = archives

                    // Stop polling if all archives are available or if any failed
                    if Self.shouldStopPolling(archives) {
                        state.removeTask(for: sessionKey)
                        return
                    }

                    // Wait before next poll
                    try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))

                } catch {
                    guard !Task.isCancelled else { return }
                    publisher.send(completion: .failure(error))
                    state.removeTask(for: sessionKey)
                    return
                }
            } while !Task.isCancelled
        }

        state.setTask(task, for: sessionKey)
    }

    private static func shouldStopPolling(_ archives: [Archive]) -> Bool {
        guard !archives.isEmpty else { return true }

        // Stop if any archive failed (they won't become available)
        if archives.contains(where: { $0.status == .failed }) {
            return true
        }

        // Stop if all archives are available for download
        return archives.allSatisfy { $0.status == .available }
    }
}
