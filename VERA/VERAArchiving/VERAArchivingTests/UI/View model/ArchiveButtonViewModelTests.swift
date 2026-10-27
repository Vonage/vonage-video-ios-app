//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERAArchivingTestHelpers
import VERADomain
import VERATestHelpers

@MainActor
@Suite("Archive button view model tests")
struct ArchiveButtonViewModelTests {

    @Test func initialStateIsIdle() async {
        let sut = makeSUT()

        let state = sut.state

        #expect(state == .idle)
    }

    @Test func setupSubscribesToArchivingStatus() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await poll(read: { await MainActor.run { sut.state } }, until: { _ in true })

        #expect(state == .idle)
        #expect(dataSource.archivingStatusCallCount == 1)
    }

    @Test func setupChangesStateToArchivingWhenDataSourceReturnsArchiving() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        let archiveID = "test-archive-id"
        dataSource._archivingState.value = .archiving(archiveID)
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await poll(read: { await MainActor.run { sut.state } }, until: { $0.isArchiving })

        #expect(state == .archiving(archiveID))
    }

    @Test func setupChangesStateToIdleWhenDataSourceReturnsFalse() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        dataSource._archivingState.value = .idle
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()

        let state = await poll(read: { await MainActor.run { sut.state } }, until: { _ in true })

        #expect(state == .idle)
    }

    @Test
    @MainActor
    func bottomItemPresentationUsesIdleState() {
        let sut = makeSUT()

        #expect(sut.id == "archive-button")
        #expect(sut.label == String(localized: "Start Recording"))
        #expect(sut.accessibilityIdentifier == ArchivingAccessibilityID.startRecordingButton)
        #expect(sut.isActive == false)
        #expect(sut.accessory == nil)
        _ = sut.image
    }

    @Test
    @MainActor
    func bottomItemPresentationUsesArchivingState() {
        let sut = makeSUT()
        sut.state = .archiving("archive-id")

        #expect(sut.id == "archive-button")
        #expect(sut.label == String(localized: "Stop Recording"))
        #expect(sut.accessibilityIdentifier == ArchivingAccessibilityID.stopRecordingButton)
        #expect(sut.isActive)
        #expect(sut.accessory == nil)
        _ = sut.image
    }

    @Test
    @MainActor
    func bottomItemPerformActionUsesButtonTap() {
        let alertSpy = AlertSpy()
        let sut = makeSUT(showAlert: alertSpy.capture)

        sut.performAction()

        #expect(alertSpy.capturedAlert != nil)
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
        #expect(startUseCase.lastRequest?.sessionKey == "heart-of-gold")
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
        _ = await poll(read: { await MainActor.run { sut.state } }, until: { $0.isArchiving })

        sut.onTap()

        #expect(alertSpy.capturedAlert != nil)
        #expect(alertSpy.capturedAlert?.onConfirm != nil)
        #expect(stopUseCase.callCount == 0)

        // Simulate user confirming
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.callCount == 1)
        #expect(stopUseCase.lastRequest?.archiveID == "archive-123")
        #expect(stopUseCase.lastRequest?.sessionKey == "heart-of-gold")
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
        _ = await poll(read: { await MainActor.run { sut.state } }, until: { $0.isArchiving })

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
        _ = await poll(read: { await MainActor.run { sut.state } }, until: { $0.isArchiving })

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
        _ = await poll(read: { await MainActor.run { sut.state } }, until: { $0.isArchiving })
        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        // Try to start again
        dataSource._archivingState.value = .idle
        _ = await poll(read: { await MainActor.run { sut.state } }, until: { !$0.isArchiving })
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
        _ = await poll(read: { await MainActor.run { sut.state } }, until: { $0.isArchiving })

        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.callCount == 1)
    }

    // MARK: - Transcription

    @Test
    @MainActor
    func transcriptionBottomItemPresentationUsesIdleState() {
        let sut = makeSUT(kind: .transcription)

        #expect(sut.id == "transcription-button")
        #expect(sut.label == String(localized: "Start Transcription"))
        #expect(sut.accessibilityIdentifier == ArchivingAccessibilityID.startTranscriptionButton)
        #expect(sut.isActive == false)
        _ = sut.image
    }

    @Test
    @MainActor
    func transcriptionBottomItemPresentationUsesArchivingState() {
        let sut = makeSUT(kind: .transcription)
        sut.state = .archiving("transcription-id")

        #expect(sut.id == "transcription-button")
        #expect(sut.label == String(localized: "Stop Transcription"))
        #expect(sut.accessibilityIdentifier == ArchivingAccessibilityID.stopTranscriptionButton)
        #expect(sut.isActive)
        _ = sut.image
    }

    @Test func recordingStartRequestsRecordingKind() async {
        let startUseCase = SpyStartArchivingUseCase()
        let alertSpy = AlertSpy()
        let sut = makeSUT(startArchivingUseCase: startUseCase, showAlert: alertSpy.capture)

        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.lastRequest?.kind == .recording)
    }

    @Test func transcriptionTapShowsStartTranscriptionConfirmation() async {
        let alertSpy = AlertSpy()
        let sut = makeSUT(kind: .transcription, showAlert: alertSpy.capture)

        sut.onTap()

        #expect(alertSpy.capturedAlert?.title == String(localized: "Start Transcription?"))
    }

    @Test func transcriptionStartRequestsTranscriptionKind() async {
        let startUseCase = SpyStartArchivingUseCase()
        let alertSpy = AlertSpy()
        let sut = makeSUT(
            kind: .transcription,
            startArchivingUseCase: startUseCase,
            showAlert: alertSpy.capture)

        sut.onTap()
        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(startUseCase.callCount == 1)
        #expect(startUseCase.lastRequest?.kind == .transcription)
        #expect(startUseCase.lastRequest?.sessionKey == "heart-of-gold")
    }

    @Test func transcriptionButtonIgnoresRecordingState() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        dataSource._archivingState.value = .archiving("recording-1")
        let sut = makeSUT(kind: .transcription, archivingStatusDataSource: dataSource)

        sut.setup()
        dataSource._transcriptionState.value = .archiving("transcription-1")
        let state = await poll(read: { sut.state }) { $0.isArchiving }

        #expect(state == .archiving("transcription-1"))
    }

    @Test func recordingButtonIgnoresTranscriptionState() async {
        let dataSource = ArchivingStatusDataSourceSpy()
        dataSource._transcriptionState.value = .archiving("transcription-1")
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        sut.setup()
        dataSource._archivingState.value = .archiving("recording-1")
        let state = await poll(read: { sut.state }) { $0.isArchiving }

        #expect(state == .archiving("recording-1"))
    }

    @Test func transcriptionStopSendsTranscriptionArchiveID() async {
        let stopUseCase = SpyStopArchivingUseCase()
        let dataSource = ArchivingStatusDataSourceSpy()
        let alertSpy = AlertSpy()
        dataSource._transcriptionState.value = .archiving("transcription-123")
        let sut = makeSUT(
            kind: .transcription,
            stopArchivingUseCase: stopUseCase,
            archivingStatusDataSource: dataSource,
            showAlert: alertSpy.capture)

        sut.setup()
        _ = await poll(read: { sut.state }) { $0.isArchiving }

        sut.onTap()
        #expect(alertSpy.capturedAlert?.title == String(localized: "Stop Transcription?"))

        alertSpy.capturedAlert?.onConfirm?()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(stopUseCase.callCount == 1)
        #expect(stopUseCase.lastRequest?.archiveID == "transcription-123")
        #expect(stopUseCase.lastRequest?.kind == .transcription)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        kind: ArchiveKind = .recording,
        sessionKey: String = "heart-of-gold",
        startArchivingUseCase: StartArchivingUseCase? = nil,
        stopArchivingUseCase: StopArchivingUseCase? = nil,
        archivingStatusDataSource: ArchivingStatusDataSource = ArchivingStatusDataSourceSpy(),
        showAlert: @escaping (AlertItem) -> Void = { _ in }
    ) -> ArchiveButtonViewModel {
        let holder = DefaultSessionKeyHolder()
        holder.setSessionKey(sessionKey)
        return ArchiveButtonViewModel(
            kind: kind,
            sessionKeyProvider: holder,
            startArchivingUseCase: startArchivingUseCase ?? SpyStartArchivingUseCase(),
            stopArchivingUseCase: stopArchivingUseCase ?? SpyStopArchivingUseCase(),
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

@MainActor
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

@MainActor
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
