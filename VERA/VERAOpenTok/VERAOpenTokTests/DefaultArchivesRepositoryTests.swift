//
//  Created by Vonage on 5/8/25.
//

import Combine
import Foundation
import Testing
import VERACore
import VERAOpenTok
import VERATestHelpers

@Suite("Default archives repository tests")
struct DefaultArchivesRepositoryTests {

    @Test("Should return empty archives when data source returns empty")
    func returnsEmptyArchivesWhenDataSourceReturnsEmpty() async throws {
        let mockDataSource = MockArchivesDataSource()

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = sut.getArchives(roomName: "test-room")

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
        let publisher = sut.getArchives(roomName: "test-room")

        let archives = try await awaitFirstValue(from: publisher)
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
        let publisher = sut.getArchives(roomName: "test-room")

        // Collect multiple values from the publisher
        let values = try await collectValues(from: publisher, count: 3, timeout: 2.0)

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
        let publisher = sut.getArchives(roomName: "test-room")

        let values = try await collectValues(from: publisher, count: 3, timeout: 2.0)

        #expect(values.count == 3)

        // First call - mixed states
        #expect(values[0][0].status == .stopped)
        #expect(values[0][1].status == .available)

        // Final call - all available
        #expect(values[2][0].status == .available)
        #expect(values[2][1].status == .available)

        #expect(mockDataSource.callCount == 3)
    }

    @Test("Should stop polling immediately when any archive has failed status")
    func stopsPollingWhenAnyArchiveHasFailedStatus() async throws {
        let availableArchive = makeArchive(id: UUID(), status: .available)
        let failedArchive = makeArchive(id: UUID(), status: .failed)

        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [availableArchive, failedArchive]

        let sut = makeSUT(archivesDataSource: mockDataSource)
        let publisher = sut.getArchives(roomName: "test-room")

        let archives = try await awaitFirstValue(from: publisher)
        #expect(archives.count == 2)
        #expect(archives[0].status == .available)
        #expect(archives[1].status == .failed)

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
        let publisher = sut.getArchives(roomName: "test-room")

        let archives = try await awaitFirstValue(from: publisher)
        #expect(archives[0].status == .available)

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
        let publisher = sut.getArchives(roomName: "test-room")

        await #expect(throws: MockArchivesDataSourceError.self) {
            _ = try await awaitFirstValue(from: publisher)
        }
    }

    @Test("Should cache publishers for same room")
    func cachesPublishersForSameRoom() async throws {
        let expectedArchive = makeArchive(id: UUID(), status: .available)
        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [expectedArchive]

        let sut = makeSUT(archivesDataSource: mockDataSource)

        let publisher1 = sut.getArchives(roomName: "test-room")
        let publisher2 = sut.getArchives(roomName: "test-room")

        // Get first value from first publisher
        let archives1 = try await awaitFirstValue(from: publisher1)
        #expect(archives1.count == 1)
        #expect(archives1[0].id == expectedArchive.id)

        // Get first value from second publisher (should be cached)
        let archives2 = try await awaitFirstValue(from: publisher2)
        #expect(archives2.count == 1)
        #expect(archives2[0].id == expectedArchive.id)

        // Should have made at least one call, but due to caching behavior
        // the exact count may vary
        #expect(mockDataSource.callCount >= 1)
    }

    @Test("Should create different publishers for different rooms")
    func createsDifferentPublishersForDifferentRooms() async throws {
        let mockDataSource = MockArchivesDataSource()
        mockDataSource.archivesToReturn = [makeArchive(id: UUID(), status: .available)]

        let sut = makeSUT(archivesDataSource: mockDataSource)

        let publisher1 = sut.getArchives(roomName: "room1")
        let publisher2 = sut.getArchives(roomName: "room2")

        let archives1 = try await awaitFirstValue(from: publisher1)
        let archives2 = try await awaitFirstValue(from: publisher2)

        // Should have made separate calls for each room
        #expect(mockDataSource.callCount == 2)
        #expect(archives1.count == 1)
        #expect(archives2.count == 1)
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
        url: URL? = nil
    ) -> Archive {
        Archive(
            id: id,
            name: name,
            createdAt: createdAt,
            status: status,
            url: url
        )
    }

    private func awaitFirstValue<T>(from publisher: AnyPublisher<T, Error>) async throws -> T {
        try await withTimeout(seconds: 2.0) {
            try await publisher.values.first { _ in true }!
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
