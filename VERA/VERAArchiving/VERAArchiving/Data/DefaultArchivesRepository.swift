//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation
import VERADomain

public final class DefaultArchivesRepository: ArchivesRepository {
    private let archivesDataSource: ArchivesDataSource
    private var cache: [String: CurrentValueSubject<[Archive], Error>] = [:]
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private let pollingInterval: TimeInterval

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
        let publisher = getPublisher(sessionKey: sessionKey)

        // Start polling
        startPolling(for: sessionKey, publisher: publisher)

        return publisher.eraseToAnyPublisher()
    }

    private func startPolling(
        for sessionKey: String,
        publisher: CurrentValueSubject<[Archive], Error>
    ) {
        // Cancel any existing polling task for this room
        pollingTasks[sessionKey]?.cancel()

        let task = Task {
            repeat {
                do {
                    let archives = try await archivesDataSource.getArchives(sessionKey: sessionKey)

                    // Check if task was cancelled
                    guard !Task.isCancelled else { return }

                    publisher.value = archives

                    // Stop polling if all archives are available or if any failed
                    if shouldStopPolling(archives) {
                        pollingTasks.removeValue(forKey: sessionKey)
                        return
                    }

                    // Wait before next poll
                    try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))

                } catch {
                    guard !Task.isCancelled else { return }
                    publisher.send(completion: .failure(error))
                    pollingTasks[sessionKey] = nil
                    return
                }
            } while !Task.isCancelled
        }

        pollingTasks[sessionKey] = task
    }

    private func shouldStopPolling(_ archives: [Archive]) -> Bool {
        guard !archives.isEmpty else { return true }

        // Stop if any archive failed (they won't become available)
        if archives.contains(where: { $0.status == .failed }) {
            return true
        }

        // Stop if all archives are available for download
        return archives.allSatisfy { $0.status == .available }
    }

    private func getPublisher(
        sessionKey: String
    ) -> CurrentValueSubject<[Archive], Error> {
        if let publisher = cache[sessionKey] {
            return publisher
        }
        let publisher = CurrentValueSubject<[Archive], Error>([])
        cache[sessionKey] = publisher
        return publisher
    }
}
