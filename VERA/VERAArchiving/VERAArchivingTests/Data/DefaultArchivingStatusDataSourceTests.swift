//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERADomain

@Suite("Default archiving status data source tests")
struct DefaultArchivingStatusDataSourceTests {

    // MARK: - Initial State Tests

    @Test("Initial archiving state is idle")
    func initialArchivingStateIsIdle() async throws {
        let sut = makeSUT()

        let status = await sut.archivingState.nextValue()

        #expect(status == .idle)
    }

    // MARK: - Set Archiving State Tests

    @Test("Setting archiving state to archiving updates publisher")
    func settingArchivingStateToArchivingUpdatesPublisher() async throws {
        let sut = makeSUT()
        let archiveID = "test-archive-123"

        sut.set(archivingState: .archiving(archiveID))

        let status = await sut.archivingState.nextValue()
        #expect(status == .archiving(archiveID))
    }

    @Test("Setting archiving state to idle updates publisher")
    func settingArchivingStateToIdleUpdatesPublisher() async throws {
        let sut = makeSUT()

        sut.set(archivingState: .idle)

        let status = await sut.archivingState.nextValue()
        #expect(status == .idle)
    }

    @Test("Setting archiving state multiple times updates publisher correctly")
    func settingArchivingStateMultipleTimesUpdatesPublisherCorrectly() async throws {
        let sut = makeSUT()
        let archiveID1 = "archive-1"
        let archiveID2 = "archive-2"

        // Set to archiving
        sut.set(archivingState: .archiving(archiveID1))
        var status = await sut.archivingState.nextValue()
        #expect(status == .archiving(archiveID1))

        // Set to idle
        sut.set(archivingState: .idle)
        status = await sut.archivingState.nextValue()
        #expect(status == .idle)

        // Set to archiving again with different ID
        sut.set(archivingState: .archiving(archiveID2))
        status = await sut.archivingState.nextValue()
        #expect(status == .archiving(archiveID2))
    }

    // MARK: - Reset Tests

    @Test("Reset sets archiving state to idle")
    func resetSetsArchivingStateToIdle() async throws {
        let sut = makeSUT()
        let archiveID = "test-archive"

        // Set to archiving first
        sut.set(archivingState: .archiving(archiveID))
        var status = await sut.archivingState.nextValue()
        #expect(status == .archiving(archiveID))

        // Reset
        sut.reset()
        status = await sut.archivingState.nextValue()
        #expect(status == .idle)
    }

    @Test("Reset when already idle keeps state idle")
    func resetWhenAlreadyIdleKeepsStateIdle() async throws {
        let sut = makeSUT()

        // Initial state is already idle
        var status = await sut.archivingState.nextValue()
        #expect(status == .idle)

        // Reset
        sut.reset()
        status = await sut.archivingState.nextValue()
        #expect(status == .idle)
    }

    @Test("Multiple resets keep state idle")
    func multipleResetsKeepStateIdle() async throws {
        let sut = makeSUT()
        let archiveID = "test-archive"

        sut.set(archivingState: .archiving(archiveID))

        // Multiple resets
        sut.reset()
        var status = await sut.archivingState.nextValue()
        #expect(status == .idle)

        sut.reset()
        status = await sut.archivingState.nextValue()
        #expect(status == .idle)

        sut.reset()
        status = await sut.archivingState.nextValue()
        #expect(status == .idle)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> DefaultArchivingStatusDataSource {
        DefaultArchivingStatusDataSource()
    }
}

extension AnyPublisher where Failure == Never {
    func nextValue() async -> Output {
        await values.first { _ in true }!
    }
}
