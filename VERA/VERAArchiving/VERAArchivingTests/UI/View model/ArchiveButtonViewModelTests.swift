//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERAArchivingTestHelpers
import VERADomain

@Suite("Archive button view model tests")
struct ArchiveButtonViewModelTests {

    @Test func initialStateIsIdle() async {
        let sut = makeSUT()

        let state = await sut.$state.values.first { _ in true }

        #expect(state == .idle)
    }

    @Test func setupSubscribesToArchivingStatus() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await sut.$state.values.first { _ in true }

        #expect(state == .idle)
        #expect(dataSource.archivingStatusCallCount == 1)
    }

    @Test func setupChangesStateToArchivingWhenDataSourceReturnsArchiving() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        let archiveID = "test-archive-id"
        dataSource._archivingState.value = .archiving(archiveID)
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await sut.$state.values.first { $0.isArchiving }

        #expect(state == .archiving(archiveID))
    }

    @Test func setupChangesStateToIdleWhenDataSourceReturnsFalse() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        dataSource._archivingState.value = .idle
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await sut.$state.values.first { _ in true }

        #expect(state == .idle)
    }

    @Test func setupOnlySubscribesOnce() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()
        sut.setup()
        sut.setup()

        #expect(dataSource.archivingStatusCallCount == 1)
    }

    @Test func onTapShowsStartRecordingConfirmation() async {
        let startUseCase = SpyStartArchivingUseCase()
        let alertSpy = AlertSpy()
        let sut = makeSUT(startArchivingUseCase: startUseCase, showAlert: alertSpy.capture)

        sut.onTap()

        #expect(alertSpy.capturedAlert != nil)
        #expect(alertSpy.capturedAlert?.onConfirm != nil)
        #expect(startUseCase.callCount == 0)

        // Simulate user confirming
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.callCount == 1)
        #expect(startUseCase.lastRequest?.roomName == "heart-of-gold")
    }

    @Test func onTapShowsStopRecordingConfirmation() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.archiveID = "archive-123"
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = ArchivingStatusDataSourceSpy()
        let alertSpy = AlertSpy()
        dataSource._archivingState.value = .archiving("archive-123")
        let sut = makeSUT(
            startArchivingUseCase: startUseCase,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource,
            showAlert: alertSpy.capture
        )

        sut.setup()
        _ = await sut.$state.values.first { $0.isArchiving }

        sut.onTap()

        #expect(alertSpy.capturedAlert != nil)
        #expect(alertSpy.capturedAlert?.onConfirm != nil)
        #expect(stopUseCase.callCount == 0)

        // Simulate user confirming
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.callCount == 1)
        #expect(stopUseCase.lastRequest?.archiveID == "archive-123")
        #expect(stopUseCase.lastRequest?.roomName == "heart-of-gold")
    }

    @Test func onTapStopsArchivingWhenArchiveIDPresent() async {
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = ArchivingStatusDataSourceSpy()
        let alertSpy = AlertSpy()
        let archiveID = "test-archive"
        dataSource._archivingState.value = .archiving(archiveID)
        let sut = makeSUT(
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource,
            showAlert: alertSpy.capture
        )

        sut.setup()
        _ = await sut.$state.values.first { $0.isArchiving }

        sut.onTap()

        #expect(alertSpy.capturedAlert != nil)

        // Simulate user confirming
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.callCount == 1)
        #expect(stopUseCase.lastRequest?.archiveID == archiveID)
    }

    @Test func startArchivingStoresArchiveID() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.archiveID = "new-archive-456"
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = ArchivingStatusDataSourceSpy()
        let alertSpy = AlertSpy()
        let sut = makeSUT(
            startArchivingUseCase: startUseCase,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource,
            showAlert: alertSpy.capture
        )

        dataSource._archivingState.value = .idle
        sut.setup()

        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        dataSource._archivingState.value = .archiving("new-archive-456")
        _ = await sut.$state.values.first { $0.isArchiving }

        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.lastRequest?.archiveID == "new-archive-456")
    }

    @Test func stopArchivingClearsArchiveID() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.archiveID = "archive-789"
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = ArchivingStatusDataSourceSpy()
        let alertSpy = AlertSpy()
        let sut = makeSUT(
            startArchivingUseCase: startUseCase,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource,
            showAlert: alertSpy.capture
        )

        sut.setup()

        // Start archiving
        dataSource._archivingState.value = .idle
        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        // Stop archiving
        dataSource._archivingState.value = .archiving("archive-789")
        _ = await sut.$state.values.first { $0.isArchiving }
        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        // Try to start again
        dataSource._archivingState.value = .idle
        _ = await sut.$state.values.first { !$0.isArchiving }
        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.callCount == 2)
    }

    @Test func startArchivingHandlesError() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.shouldThrowError = true
        let alertSpy = AlertSpy()
        let sut = makeSUT(startArchivingUseCase: startUseCase, showAlert: alertSpy.capture)

        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()

        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.callCount == 1)
    }

    @Test func stopArchivingHandlesError() async {
        let startUseCase = SpyStartArchivingUseCase()
        startUseCase.archiveID = "archive-error"
        let stopUseCase = SpyStopArchivingUseCase()
        stopUseCase.shouldThrowError = true
        let dataSource = ArchivingStatusDataSourceSpy()
        let alertSpy = AlertSpy()
        dataSource._archivingState.value = .archiving("archive-error")
        let sut = makeSUT(
            startArchivingUseCase: startUseCase,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource,
            showAlert: alertSpy.capture
        )

        sut.setup()
        _ = await sut.$state.values.first { $0.isArchiving }

        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.callCount == 1)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        roomName: RoomName = "heart-of-gold",
        startArchivingUseCase: StartArchivingUseCase = SpyStartArchivingUseCase(),
        stopArchivingUseCase: StopArchivingUseCase = SpyStopArchivingUseCase(),
        archivingStatusDataSource: ArchivingStatusDataSource = ArchivingStatusDataSourceSpy(),
        showAlert: @escaping (AlertItem) -> Void = { _ in }
    ) -> ArchiveButtonViewModel {
        ArchiveButtonViewModel(
            roomName: roomName,
            startArchivingUseCase: startArchivingUseCase,
            stopArchivingUseCase: stopArchivingUseCase,
            archivingStatusDataSource: archivingStatusDataSource,
            showAlert: showAlert
        )
    }
}

// MARK: - Spies

final class AlertSpy {
    var capturedAlert: AlertItem?

    func capture(_ alert: AlertItem) {
        capturedAlert = alert
    }
}

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
