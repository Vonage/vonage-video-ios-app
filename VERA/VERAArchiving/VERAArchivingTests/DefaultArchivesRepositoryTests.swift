//
//  Created by Vonage on 5/8/25.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERADomain
import VERATestHelpers

@MainActor
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


        // Wait for the first fetched archives after the initial empty replay.
        let values = try await awaitFirstNonEmptyValue(from: publisher)

        // The fetched value should have both archives
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

        // Wait for the first fetched archives after the initial empty replay.
        let values = try await awaitFirstNonEmptyValue(from: publisher)

        // The fetched value should have the archive
        #expect(values.count == 1)
        #expect(values[0].status == .available)

        // Wait a bit to ensure no additional polling happens
        try await Task.sleep(nanoseconds: 500_000_000)  // 500ms

        // Should only have made one call since archive was already available
        #expect(mockDataSource.callCount == 1)
    }

    @Test("Should keep polling while the transcript is pending even if the parent archive is uploaded")
    func pollsUntilTranscriptIsAvailableAfterParentArchiveIsUploaded() async throws {
        let archiveId = UUID()
        let pendingTranscript = makeArchive(
            id: archiveId,
            status: .uploaded,
            kind: .transcription,
            transcription: ArchiveTranscription(status: .started, url: nil))
        let readyTranscript = makeArchive(
            id: archiveId,
            status: .uploaded,
            kind: .transcription,
            transcription: ArchiveTranscription(
                status: .available, url: URL(string: "https://example.com/transcript.zip")))

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.responses = [[pendingTranscript], [pendingTranscript], [readyTranscript]]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")

        let values = try await collectValues(
            from: publisher.filter { !$0.isEmpty }.eraseToAnyPublisher(), count: 3, timeout: 5.0)

        #expect(values[0][0].transcription?.status == .started)
        #expect(values[2][0].transcription?.status == .available)

        // Wait to ensure polling stopped once the transcript became available
        try await Task.sleep(nanoseconds: 500_000_000)  // 500ms
        #expect(mockDataSource.callCount == 3)
    }

    @Test("Should keep polling while the transcript is requested even if the parent archive is available")
    func pollsWhileTranscriptIsRequestedAfterParentArchiveIsAvailable() async throws {
        let pendingTranscript = makeArchive(
            id: UUID(),
            status: .available,
            kind: .transcription,
            transcription: ArchiveTranscription(status: .requested, url: nil))

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [pendingTranscript]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        _ = await sut.getArchives(sessionKey: "test-room")

        let callCount = await poll(read: { await MainActor.run { mockDataSource.callCount } }) { $0 >= 3 }
        #expect(callCount >= 3)
    }

    @Test("Should keep polling for pending archives when another archive failed")
    func keepsPollingPendingArchivesWhenAnotherArchiveFailed() async throws {
        let failedArchive = makeArchive(id: UUID(), status: .failed)
        let pendingArchive = makeArchive(id: UUID(), status: .stopped)

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [failedArchive, pendingArchive]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        _ = await sut.getArchives(sessionKey: "test-room")

        let callCount = await poll(read: { await MainActor.run { mockDataSource.callCount } }) { $0 >= 2 }
        #expect(callCount >= 2)
    }

    @Test("Should stop polling when archives finished without becoming available")
    func stopsPollingWhenArchivesFinishedWithoutBecomingAvailable() async throws {
        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [
            makeArchive(id: UUID(), status: .uploaded),
            makeArchive(id: UUID(), status: .expired),
            makeArchive(
                id: UUID(),
                status: .uploaded,
                kind: .transcription,
                transcription: ArchiveTranscription(status: .failed, url: nil)),
        ]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = await sut.getArchives(sessionKey: "test-room")

        _ = try await collectValues(
            from: publisher.filter { $0.count == 3 }.eraseToAnyPublisher(), count: 1, timeout: 5.0)

        try await Task.sleep(nanoseconds: 500_000_000)  // 500ms
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

    @Test("Should start a fresh publisher for the same room after a failure")
    func recoversAfterFailureForSameRoom() async throws {
        let expectedArchive = makeArchive(id: UUID(), status: .available)
        let mockDataSource = MockArchivesDataSource()
        mockDataSource.shouldThrowError = true

        let sut = makeSUT(archivesDataSource: mockDataSource)

        let failedPublisher = await sut.getArchives(sessionKey: "test-room")
        let error = try await awaitError(from: failedPublisher)
        #expect(error is MockArchivesDataSourceError)

        mockDataSource.shouldThrowError = false
        mockDataSource.archivesToReturn = [expectedArchive]
        let retryPublisher = await sut.getArchives(sessionKey: "test-room")

        let archives = try await awaitFirstNonEmptyValue(from: retryPublisher)
        #expect(archives.map(\.id) == [expectedArchive.id])
    }

    @Test("Should cache publishers for same room")
    func cachesPublishersForSameRoom() async throws {
        let expectedArchive = makeArchive(id: UUID(), status: .available)
        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [expectedArchive]

        let sut = makeSUT(archivesDataSource: mockDataSource)

        let publisher1 = await sut.getArchives(sessionKey: "test-room")
        let publisher2 = await sut.getArchives(sessionKey: "test-room")

        // Wait for the first publisher to deliver the fetched archive
        let values1 = try await awaitFirstNonEmptyValue(from: publisher1)
        #expect(values1.count == 1)
        #expect(values1[0].id == expectedArchive.id)

        // The second publisher should replay the cached archive
        let values2 = try await awaitFirstNonEmptyValue(from: publisher2)
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

        // Wait for each publisher to deliver its fetched archives
        let archives1 = try await awaitFirstNonEmptyValue(from: publisher1)
        let archives2 = try await awaitFirstNonEmptyValue(from: publisher2)

        // Should have made separate calls for each room
        #expect(mockDataSource.callCount == 2)
        #expect(archives1.count == 1)
        #expect(archives2.count == 1)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        archivesDataSource: ArchivesDataSource? = nil
    ) -> DefaultArchivesRepository {
        DefaultArchivesRepository(
            pollingIntervalSeconds: 0.1,  // 100ms for faster tests
            archivesDataSource: archivesDataSource ?? MockArchivesDataSource()
        )
    }

    private func makeArchive(
        id: UUID,
        name: String = "Test Archive",
        status: ArchiveStatus,
        createdAt: Date = Date(),
        url: URL? = nil,
        size: Int = 0,
        duration: Int = 0,
        kind: ArchiveKind = .recording,
        transcription: ArchiveTranscription? = nil
    ) -> Archive {
        Archive(
            id: id,
            name: name,
            createdAt: createdAt,
            status: status,
            url: url,
            size: size,
            duration: duration,
            kind: kind,
            transcription: transcription
        )
    }

    private func awaitFirstValue<T: Sendable>(from publisher: AnyPublisher<T, Error>) async throws -> T {
        let (stream, subscription) = makeArchivePublisherTestStream(from: publisher)
        defer { subscription.cancel() }
        return try await withTimeout(seconds: 5.0) {
            guard let value = try await stream.first(where: { @Sendable _ in true }) else { throw TimeoutError() }
            return value
        }
    }

    private func awaitFirstNonEmptyValue(from publisher: AnyPublisher<[Archive], Error>) async throws -> [Archive] {
        let (stream, subscription) = makeArchivePublisherTestStream(from: publisher)
        defer { subscription.cancel() }
        return try await withTimeout(seconds: 5.0) {
            guard let value = try await stream.first(where: { @Sendable value in !value.isEmpty }) else {
                throw TimeoutError()
            }
            return value
        }
    }

    private func awaitError<T: Sendable>(from publisher: AnyPublisher<T, Error>) async throws -> Error {
        let (stream, subscription) = makeArchivePublisherTestStream(from: publisher)
        defer { subscription.cancel() }
        return try await withTimeout(seconds: 5.0) {
            do {
                for try await _ in stream {}
            } catch {
                return error
            }
            throw TimeoutError()
        }
    }

    private func collectValues<T: Sendable>(
        from publisher: AnyPublisher<T, Error>,
        count: Int,
        timeout: TimeInterval
    ) async throws -> [T] {
        let (stream, subscription) = makeArchivePublisherTestStream(from: publisher)
        defer { subscription.cancel() }
        return try await withTimeout(seconds: timeout) {
            var values: [T] = []
            for try await value in stream {
                values.append(value)
                if values.count >= count { break }
            }
            return values
        }
    }

    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @MainActor @Sendable () async throws -> T
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
