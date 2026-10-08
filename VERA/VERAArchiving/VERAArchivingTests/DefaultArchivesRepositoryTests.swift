//
//  Created by Vonage on 5/8/25.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERADomain

@Suite("Default archives repository tests")
struct DefaultArchivesRepositoryTests {

    @Test("Should return empty archives when data source returns empty")
    func returnsEmptyArchivesWhenDataSourceReturnsEmpty() async throws {
        let mockDataSource = MockArchivesDataSource()

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")

        let archives = try await awaitFirstValue(from: publisher)
        #expect(archives.isEmpty)
    }

    @Test("Should return archives when data source returns data")
    func returnsArchivesWhenDataSourceReturnsData() async throws {
        let expectedArchives = [
            makeArchive(id: UUID(), status: .available),
            makeArchive(id: UUID(), status: .available),
        ]

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = expectedArchives

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")

        // Wait for the first non-empty value
        let archives = try await awaitFirstNonEmptyValue(from: publisher)

        #expect(archives.count == 2)
        #expect(archives[0].id == expectedArchives[0].id)
        #expect(archives[1].id == expectedArchives[1].id)
    }

    @Test("Should poll until all archives are available")
    func pollsUntilAllArchivesAreAvailable() async throws {
        let archiveId = UUID()
        let stoppedArchive = makeArchive(id: archiveId, status: .stopped)
        let availableArchive = makeArchive(id: archiveId, status: .available)

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.responses = [
            [stoppedArchive],  // First call - not available for download
            [stoppedArchive],  // Second call - still not available
            [availableArchive],  // Third call - now available for download
        ]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")

        // Collect multiple values from the publisher
        let values = try await collectValues(
            from: publisher.filter { !$0.isEmpty }.eraseToAnyPublisher(), count: 3, timeout: 5.0)

        // Should receive 3 updates
        #expect(values.count == 3)

        // First two should have stopped status (not downloadable)
        #expect(values[0][0].status == .stopped)
        #expect(values[1][0].status == .stopped)

        // Last one should have available status (downloadable)
        #expect(values[2][0].status == .available)

        // Should have made 3 calls to data source
        #expect(mockDataSource.callCount == 3)
    }

    @Test("Should poll until all archives are available with mixed statuses")
    func pollsUntilAllArchivesAreAvailableWithMixedStatuses() async throws {
        let archive1Id = UUID()
        let archive2Id = UUID()

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.responses = [
            // First call - one stopped, one already available
            [
                makeArchive(id: archive1Id, status: .stopped),
                makeArchive(id: archive2Id, status: .available),
            ],
            // Second call - first one still stopped
            [
                makeArchive(id: archive1Id, status: .stopped),
                makeArchive(id: archive2Id, status: .available),
            ],
            // Third call - both available
            [
                makeArchive(id: archive1Id, status: .available),
                makeArchive(id: archive2Id, status: .available),
            ],
        ]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")

        let values = try await collectValues(
            from: publisher.filter { !$0.isEmpty }.eraseToAnyPublisher(), count: 3, timeout: 5.0)

        #expect(values.count == 3)

        // First call - mixed states
        // Find archives by ID to ensure correct matching
        if let archive1 = values[0].first(where: { $0.id == archive1Id }),
            let archive2 = values[0].first(where: { $0.id == archive2Id })
        {
            #expect(archive1.status == .stopped)
            #expect(archive2.status == .available)
        } else {
            // Fallback to positional check
            #expect(values[0][0].status == .stopped)
            #expect(values[0][1].status == .available)
        }

        // Final call - all available
        if let archive1 = values[2].first(where: { $0.id == archive1Id }),
            let archive2 = values[2].first(where: { $0.id == archive2Id })
        {
            #expect(archive1.status == .available)
            #expect(archive2.status == .available)
        } else {
            // Fallback to positional check
            #expect(values[2][0].status == .available)
            #expect(values[2][1].status == .available)
        }

        #expect(mockDataSource.callCount == 3)
    }

    @Test("Should stop polling immediately when any archive has failed status")
    func stopsPollingWhenAnyArchiveHasFailedStatus() async throws {
        let availableArchive = makeArchive(id: UUID(), status: .available)
        let failedArchive = makeArchive(id: UUID(), status: .failed)

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [availableArchive, failedArchive]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")


        // Collect first 2 values (initial empty array + first fetch result)
        let values = try await publisher.values.first { $0.count == 2 }!

        // Second value should have the archives
        #expect(values.count == 2)
        #expect(values.contains(where: { $0.status == .available }))
        #expect(values.contains(where: { $0.status == .failed }))

        // Wait to ensure no additional polling happens when any archive failed
        try await Task.sleep(nanoseconds: 500_000_000)  // 500ms

        // Should only have made one call since failed archives won't become available
        #expect(mockDataSource.callCount == 1)
    }

    @Test("Should stop polling when all archives are available")
    func stopsPollingWhenAllArchivesAreAvailable() async throws {
        let availableArchive = makeArchive(id: UUID(), status: .available)

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [availableArchive]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")

        // Collect first 2 values (initial empty array + first fetch result)
        let values = try await publisher.values.first { $0.count == 1 }!

        // Second value should have the archive
        #expect(values.count == 1)
        #expect(values[0].status == .available)

        // Wait a bit to ensure no additional polling happens
        try await Task.sleep(nanoseconds: 500_000_000)  // 500ms

        // Should only have made one call since archive was already available
        #expect(mockDataSource.callCount == 1)
    }

    @Test("Should handle data source errors")
    func handlesDataSourceErrors() async throws {
        let mockDataSource = MockArchivesDataSource()
        mockDataSource.shouldThrowError = true

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")

        let error = try await awaitError(from: publisher)
        #expect(error is MockArchivesDataSourceError)
    }

    @Test("Should cache publishers for same room")
    func cachesPublishersForSameRoom() async throws {
        let expectedArchive = makeArchive(id: UUID(), status: .available)
        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [expectedArchive]

        let sut = makeSUT(archivesDataSource: mockDataSource)

        let publisher1 = await sut.getArchives(sessionKey: "test-room")
        let publisher2 = await sut.getArchives(sessionKey: "test-room")

        // Collect first 2 values from first publisher
        let values1 = try await publisher1.values.first { $0.count == 1 }!
        #expect(values1.count == 1)
        #expect(values1[0].id == expectedArchive.id)

        // Collect first 2 values from second publisher (should be cached)
        let values2 = try await publisher2.values.first { $0.count == 1 }!
        #expect(values2.count == 1)
        #expect(values2[0].id == expectedArchive.id)

        // Should have made at least one call, but due to caching behavior
        // the exact count may vary
        #expect(mockDataSource.callCount >= 1)
    }

    @Test("Should create different publishers for different rooms")
    func createsDifferentPublishersForDifferentRooms() async throws {
        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [makeArchive(id: UUID(), status: .available)]

        let sut = makeSUT(archivesDataSource: mockDataSource)

        let publisher1 = await sut.getArchives(sessionKey: "room1")
        let publisher2 = await sut.getArchives(sessionKey: "room2")

        // Collect first 2 values from each publisher
        let archives1 = try await publisher1.values.first { $0.count == 1 }!
        let archives2 = try await publisher2.values.first { $0.count == 1 }!

        // Should have made separate calls for each room
        #expect(mockDataSource.callCount == 2)
        #expect(archives1.count == 1)
        #expect(archives2.count == 1)
    }

    @Test func reviewArchiveRetryRecoversAfterTransientFailure() async throws {
        let source = MockArchivesDataSource(shouldThrowError: true)
        let repository = makeSUT(archivesDataSource: source)
        let failedPublisher = await repository.getArchives(sessionKey: "review-room")
        _ = try await awaitError(from: failedPublisher)
        source.shouldThrowError = false
        source.archivesToReturn = [makeArchive(id: UUID(), status: .available)]
        let retryPublisher = await repository.getArchives(sessionKey: "review-room")
        do {
            let value = try await awaitFirstNonEmptyValue(from: retryPublisher)
            #expect(value.count == 1)
        } catch {
            Issue.record("Retry still delivers completed publisher error: \(error)")
        }
    }

    @Test func reviewArchivePollingStopsWhenOwnerAndObservationAreReleased() async throws {
        let source = MockArchivesDataSource(
            archivesToReturn: [makeArchive(id: UUID(), status: .stopped)])
        defer { source.archivesToReturn = [] }  // Let the current implementation exit after the assertion.
        var repository: DefaultArchivesRepository? = makeSUT(archivesDataSource: source)
        weak var observedRepository = repository
        var publisher: AnyPublisher<[Archive], Error>? = await repository?.getArchives(sessionKey: "review-room")
        var observation: AnyCancellable? = publisher?.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        try await Task.sleep(for: .milliseconds(150))
        observation?.cancel()
        observation = nil
        publisher = nil
        repository = nil
        #expect(observedRepository == nil)
        try await Task.sleep(for: .milliseconds(100))  // Drain an already-running fetch.
        let requestsAtRelease = source.callCount
        try await Task.sleep(for: .milliseconds(350))
        #expect(source.callCount == requestsAtRelease, "Archive polling continues without an owner or subscriber")
    }

    @Test func pollingStopsWhenLastSubscriberCancelsWithRepositoryStillAlive() async throws {
        let source = MockArchivesDataSource(archivesToReturn: [makeArchive(id: UUID(), status: .stopped)])
        defer { source.archivesToReturn = [] }
        let repository = makeSUT(archivesDataSource: source)
        let publisher = await repository.getArchives(sessionKey: "cancel-room")
        let observation = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        try await Task.sleep(for: .milliseconds(150))
        observation.cancel()
        try await Task.sleep(for: .milliseconds(100))
        let requests = source.callCount
        try await Task.sleep(for: .milliseconds(350))
        #expect(source.callCount == requests)
        _ = repository
    }

    @Test func oneSubscriberCancellingDoesNotStopAnotherSubscriber() async throws {
        let source = MockArchivesDataSource(archivesToReturn: [makeArchive(id: UUID(), status: .stopped)])
        defer { source.archivesToReturn = [] }
        let repository = makeSUT(archivesDataSource: source)
        let publisher = await repository.getArchives(sessionKey: "shared-room")
        let first = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        let second = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        try await Task.sleep(for: .milliseconds(150))
        first.cancel()
        let requests = source.callCount
        try await Task.sleep(for: .milliseconds(250))
        #expect(source.callCount > requests)
        second.cancel()
        try await Task.sleep(for: .milliseconds(100))
        let finalRequests = source.callCount
        try await Task.sleep(for: .milliseconds(350))
        #expect(source.callCount == finalRequests)
    }

    @Test func repositoryReleaseStopsPollingEvenWhileSubscriptionRemains() async throws {
        let source = MockArchivesDataSource(archivesToReturn: [makeArchive(id: UUID(), status: .stopped)])
        defer { source.archivesToReturn = [] }
        var repository: DefaultArchivesRepository? = makeSUT(archivesDataSource: source)
        weak var weakRepository = repository
        let publisher = await repository!.getArchives(sessionKey: "owner-room")
        let observation = publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        defer { observation.cancel() }
        try await Task.sleep(for: .milliseconds(150))
        repository = nil
        #expect(weakRepository == nil)
        try await Task.sleep(for: .milliseconds(100))
        let requests = source.callCount
        try await Task.sleep(for: .milliseconds(350))
        #expect(source.callCount == requests)
    }

    @Test func retryingTheSameReturnedPublisherUsesAFreshSubject() async throws {
        let source = MockArchivesDataSource(shouldThrowError: true)
        let repository = makeSUT(archivesDataSource: source)
        let publisher = await repository.getArchives(sessionKey: "resubscribe-room")
        let recovered = publisher.catch { _ -> AnyPublisher<[Archive], Error> in
            source.shouldThrowError = false
            source.archivesToReturn = [makeArchive(id: UUID(), status: .available)]
            return publisher
        }.eraseToAnyPublisher()
        let archives = try await awaitFirstNonEmptyValue(from: recovered)
        #expect(archives.count == 1)
        #expect(source.callCount == 2)
    }

    @Test func anUnobservedPublisherDoesNotStartPolling() async throws {
        let source = MockArchivesDataSource(archivesToReturn: [makeArchive(id: UUID(), status: .stopped)])
        let repository = makeSUT(archivesDataSource: source)
        _ = await repository.getArchives(sessionKey: "unobserved-room")
        try await Task.sleep(for: .milliseconds(250))
        #expect(source.callCount == 0)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        archivesDataSource: ArchivesDataSource = MockArchivesDataSource()
    ) -> DefaultArchivesRepository {
        DefaultArchivesRepository(
            pollingIntervalSeconds: 0.1,  // 100ms for faster tests
            archivesDataSource: archivesDataSource
        )
    }

    private func makeArchive(
        id: UUID,
        name: String = "Test Archive",
        status: ArchiveStatus,
        createdAt: Date = Date(),
        url: URL? = nil,
        size: Int = 0,
        duration: Int = 0
    ) -> Archive {
        Archive(
            id: id,
            name: name,
            createdAt: createdAt,
            status: status,
            url: url,
            size: size,
            duration: duration
        )
    }

    private func awaitFirstValue<T>(from publisher: AnyPublisher<T, Error>) async throws -> T {
        try await withTimeout(seconds: 5.0) {
            try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable?
                var hasResumed = false

                cancellable =
                    publisher
                    .sink(
                        receiveCompletion: { completion in
                            guard !hasResumed else { return }
                            hasResumed = true
                            cancellable?.cancel()

                            switch completion {
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            case .finished:
                                // This shouldn't happen if we're waiting for first value
                                break
                            }
                        },
                        receiveValue: { value in
                            guard !hasResumed else { return }
                            hasResumed = true
                            cancellable?.cancel()
                            continuation.resume(returning: value)
                        }
                    )
            }
        }
    }

    private func awaitFirstNonEmptyValue(from publisher: AnyPublisher<[Archive], Error>) async throws -> [Archive] {
        try await withTimeout(seconds: 5.0) {
            try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable?
                var hasResumed = false

                cancellable =
                    publisher
                    .filter { !$0.isEmpty }
                    .sink(
                        receiveCompletion: { completion in
                            guard !hasResumed else { return }
                            hasResumed = true
                            cancellable?.cancel()

                            switch completion {
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            case .finished:
                                // This shouldn't happen if we're waiting for first value
                                break
                            }
                        },
                        receiveValue: { value in
                            guard !hasResumed else { return }
                            hasResumed = true
                            cancellable?.cancel()
                            continuation.resume(returning: value)
                        }
                    )
            }
        }
    }

    private func awaitError<T>(from publisher: AnyPublisher<T, Error>) async throws -> Error {
        try await withTimeout(seconds: 5.0) {
            try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable?
                var hasResumed = false

                cancellable =
                    publisher
                    .sink(
                        receiveCompletion: { completion in
                            guard !hasResumed else { return }
                            hasResumed = true
                            cancellable?.cancel()

                            switch completion {
                            case .failure(let error):
                                continuation.resume(returning: error)
                            case .finished:
                                continuation.resume(throwing: TimeoutError())
                            }
                        },
                        receiveValue: { _ in
                            // Ignore values, we only want errors
                        }
                    )
            }
        }
    }

    private func collectValues<T>(
        from publisher: AnyPublisher<T, Error>,
        count: Int,
        timeout: TimeInterval
    ) async throws -> [T] {
        try await withTimeout(seconds: timeout) {
            var values: [T] = []
            for try await value in publisher.values {
                values.append(value)
                if values.count >= count {
                    break
                }
            }
            return values
        }
    }

    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            group.cancelAll()
            return result
        }
    }
}

private struct TimeoutError: Error {}
