//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation
import VERADomain

/// Owns each room's publisher and polling lifecycle on the UI actor.
@MainActor
public final class DefaultArchivesRepository: ArchivesRepository {
    private let archivesDataSource: ArchivesDataSource
    private let pollingInterval: TimeInterval
    private var cache: [String: CurrentValueSubject<[Archive], Error>] = [:]
    private var pollingTasks: [String: Task<Void, Never>] = [:]

    public init(
        pollingIntervalSeconds: TimeInterval = 5.0,
        archivesDataSource: ArchivesDataSource
    ) {
        self.pollingInterval = pollingIntervalSeconds
        self.archivesDataSource = archivesDataSource
    }

    deinit {
        for task in pollingTasks.values {
            task.cancel()
        }
    }

    public func getArchives(sessionKey: String) async -> AnyPublisher<[Archive], Error> {
        let publisher: CurrentValueSubject<[Archive], Error>
        if let cached = cache[sessionKey] {
            publisher = cached
        } else {
            publisher = CurrentValueSubject([])
            cache[sessionKey] = publisher
        }
        startPolling(for: sessionKey)
        return publisher.eraseToAnyPublisher()
    }

    private func startPolling(for sessionKey: String) {
        pollingTasks[sessionKey]?.cancel()
        let pollingInterval = pollingInterval
        let dataSource = archivesDataSource

        // The task owns its Sendable service, but not the UI repository while requesting or sleeping.
        pollingTasks[sessionKey] = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                let result: Result<[Archive], Error>
                do {
                    result = .success(try await dataSource.getArchives(sessionKey: sessionKey))
                } catch {
                    result = .failure(error)
                }
                guard self?.receive(result, sessionKey: sessionKey) == true else { return }
                do {
                    try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                } catch {
                    return
                }
            }
        }
    }

    /// Runs on the polling task; `startPolling` cancels a replaced task before starting the next.
    private func receive(_ result: Result<[Archive], Error>, sessionKey: String) -> Bool {
        guard !Task.isCancelled else { return false }
        switch result {
        case .success(let archives):
            cache[sessionKey]?.send(archives)
            // Stop polling once no archive or transcript is still being produced.
            // A transcript keeps processing after its parent archive is uploaded or available.
            if !archives.contains(where: \.isPending) {
                pollingTasks.removeValue(forKey: sessionKey)
                return false
            }
            return true
        case .failure(let error):
            // A failed publisher cannot emit again, so the next request starts a fresh one.
            cache.removeValue(forKey: sessionKey)?.send(completion: .failure(error))
            pollingTasks.removeValue(forKey: sessionKey)
            return false
        }
    }
}
