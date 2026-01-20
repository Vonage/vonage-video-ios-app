//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERADomain

@Suite("Archive button view model tests")
struct ArchiveButtonViewModelTests {

    @Test func initialStateIsIdle() async {
        let sut = makeSUT()

        let state = await sut.$state.values.first { _ in true }

        #expect(state == .idle)
    }

    @Test func setupSubscribesToArchivingStatus() async {
        let dataSource = SpyArchivingStatusDataSource()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await sut.$state.values.first { _ in true }

        #expect(state == .idle)
        #expect(dataSource.archivingStatusCallCount == 1)
    }

    @Test func setupChangesStateToArchivingWhenDataSourceReturnsTrue() async {
        let dataSource = SpyArchivingStatusDataSource()
        dataSource.subject.value = true
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await sut.$state.values.first { $0.isArchiving }

        #expect(state == .archiving)
    }

    @Test func setupChangesStateToIdleWhenDataSourceReturnsFalse() async {
        let dataSource = SpyArchivingStatusDataSource()
        dataSource.subject.value = false
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await sut.$state.values.first { _ in true }

        #expect(state == .idle)
    }

    @Test func setupOnlySubscribesOnce() async {
        let dataSource = SpyArchivingStatusDataSource()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()
        sut.setup()
        sut.setup()

        #expect(dataSource.archivingStatusCallCount == 1)
    }

    @Test func onTapStartsArchivingWhenStateIsIdle() async {
        let startUseCase = SpyStartArchivingUseCase()
        let sut = makeSUT(startArchivingUseCase: startUseCase)

        sut.onTap()

        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.callCount == 1)
        #expect(startUseCase.lastRequest?.roomName == "heart-of-gold")
    }

    @Test func onTapStopsArchivingWhenStateIsArchiving() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.archiveID = "archive-123"
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = SpyArchivingStatusDataSource()
        dataSource.subject.value = false
        let sut = makeSUT(
            startArchivingUseCase: startUseCase,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource
        )

        sut.setup()

        // Start archiving to populate archiveID
        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        // Change state to archiving
        dataSource.subject.value = true
        await sut.$state.values.first { $0.isArchiving }

        // Now tap to stop
        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.callCount == 1)
        #expect(stopUseCase.callCount == 1)
        #expect(stopUseCase.lastRequest?.archiveID == "archive-123")
        #expect(stopUseCase.lastRequest?.roomName == "heart-of-gold")
    }

    @Test func onTapDoesNotStopArchivingWhenNoArchiveID() async {
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = SpyArchivingStatusDataSource()
        dataSource.subject.value = true
        let sut = makeSUT(
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource
        )

        sut.setup()
        await sut.$state.values.first { $0.isArchiving }

        sut.onTap()

        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.callCount == 0)
    }

    @Test func startArchivingStoresArchiveID() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.archiveID = "new-archive-456"
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = SpyArchivingStatusDataSource()
        let sut = makeSUT(
            startArchivingUseCase: startUseCase,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource
        )

        dataSource.subject.value = false
        sut.setup()

        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        dataSource.subject.value = true
        await sut.$state.values.first { $0.isArchiving }

        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.lastRequest?.archiveID == "new-archive-456")
    }

    @Test func stopArchivingClearsArchiveID() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.archiveID = "archive-789"
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = SpyArchivingStatusDataSource()
        let sut = makeSUT(
            startArchivingUseCase: startUseCase,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource
        )

        sut.setup()

        // Start archiving
        dataSource.subject.value = false
        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        // Stop archiving
        dataSource.subject.value = true
        await sut.$state.values.first { $0.isArchiving }
        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        // Try to start again
        dataSource.subject.value = false
        await sut.$state.values.first { !$0.isArchiving }
        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.callCount == 2)
    }

    @Test func startArchivingHandlesError() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.shouldThrowError = true
        let sut = makeSUT(startArchivingUseCase: startUseCase)

        sut.onTap()

        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.callCount == 1)
    }

    @Test func stopArchivingHandlesError() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.archiveID = "archive-error"
        let stopUseCase = SpyStopArchivingUseCase()
        stopUseCase.shouldThrowError = true
        let dataSource = SpyArchivingStatusDataSource()
        dataSource.subject.value = false
        let sut = makeSUT(
            startArchivingUseCase: startUseCase,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource
        )

        sut.setup()

        // Start archiving to populate archiveID
        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        // Change state to archiving
        dataSource.subject.value = true
        await sut.$state.values.first { $0.isArchiving }

        // Now tap to stop (should handle error)
        sut.onTap()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.callCount == 1)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        roomName: RoomName = "heart-of-gold",
        startArchivingUseCase: StartArchivingUseCase = SpyStartArchivingUseCase(),
        stopArchivingUseCase: StopArchivingUseCase = SpyStopArchivingUseCase(),
        archivingStatusDataSource: ArchivingStatusDataSource = SpyArchivingStatusDataSource()
    ) -> ArchiveButtonViewModel {
        ArchiveButtonViewModel(
            roomName: roomName,
            startArchivingUseCase: startArchivingUseCase,
            stopArchivingUseCase: stopArchivingUseCase,
            archivingStatusDataSource: archivingStatusDataSource
        )
    }
}

// MARK: - Spies

final class SpyStartArchivingUseCase: StartArchivingUseCase {
    var callCount = 0
    var lastRequest: StartArchivingRequest?
    var archiveID: ArchiveID = ""
    var shouldThrowError = false

    func callAsFunction(_ request: StartArchivingRequest) async throws -> ArchiveID {
        callCount += 1
        lastRequest = request

        if shouldThrowError {
            throw NSError(domain: "test", code: -1)
        }

        return archiveID
    }
}

final class SpyStopArchivingUseCase: StopArchivingUseCase {
    var callCount = 0
    var lastRequest: StopArchivingRequest?
    var shouldThrowError = false

    func callAsFunction(_ request: StopArchivingRequest) async throws {
        callCount += 1
        lastRequest = request

        if shouldThrowError {
            throw NSError(domain: "test", code: -1)
        }
    }
}

final class SpyArchivingStatusDataSource: ArchivingStatusDataSource {
    var archivingStatusCallCount = 0
    var setCallCount = 0
    var resetCallCount = 0
    let subject = CurrentValueSubject<Bool, Never>(false)

    func archivingStatus() -> AnyPublisher<Bool, Never> {
        archivingStatusCallCount += 1
        return subject.eraseToAnyPublisher()
    }

    func set(archivingStatus: Bool) {
        setCallCount += 1
        subject.value = archivingStatus
    }

    func reset() {
        resetCallCount += 1
        subject.value = false
    }
}
