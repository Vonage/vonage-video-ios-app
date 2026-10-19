//
//  Created by Vonage on 13/1/26.
//

import Combine
import Foundation
import Observation
import VERADomain

/// Drives the start/stop control of a session archive.
///
/// The same view model controls both the recording and the post-call transcription,
/// which run as separate concurrent archives. ``kind`` selects which one.
@Observable
public final class ArchiveButtonViewModel {
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    public var state: ArchivingState = .idle

    @ObservationIgnored
    public let kind: ArchiveKind

    @ObservationIgnored
    private let sessionKeyProvider: SessionKeyProvider
    @ObservationIgnored
    private let startArchivingUseCase: StartArchivingUseCase
    @ObservationIgnored
    private let stopArchivingUseCase: StopArchivingUseCase
    @ObservationIgnored
    private let archivingStatusDataSource: ArchivingStatusDataSource
    @ObservationIgnored
    private let showAlert: (AlertItem) -> Void
    @ObservationIgnored
    private var initiated = false

    public init(
        kind: ArchiveKind = .recording,
        sessionKeyProvider: SessionKeyProvider,
        startArchivingUseCase: StartArchivingUseCase,
        stopArchivingUseCase: StopArchivingUseCase,
        archivingStatusDataSource: ArchivingStatusDataSource,
        showAlert: @escaping (AlertItem) -> Void
    ) {
        self.kind = kind
        self.sessionKeyProvider = sessionKeyProvider
        self.startArchivingUseCase = startArchivingUseCase
        self.stopArchivingUseCase = stopArchivingUseCase
        self.archivingStatusDataSource = archivingStatusDataSource
        self.showAlert = showAlert
    }

    public func setup() {
        guard !initiated else { return }
        initiated = true

        archivingStatusDataSource.archivingState(for: kind)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.state = status
            }
            .store(in: &cancellables)
    }

    public func onTap() {
        switch state {
        case .archiving(let archiveID):
            showStopConfirmation(archiveID: archiveID)
        case .idle:
            showStartConfirmation()
        }
    }

    private func showStartConfirmation() {
        showAlert(
            AlertItem(
                title: kind.startConfirmationTitle,
                message: kind.startConfirmationMessage
            ) { [weak self] in
                Task { @MainActor in
                    await self?.startArchiving()
                }
            }
        )
    }

    private func showStopConfirmation(archiveID: String) {
        showAlert(
            AlertItem(
                title: kind.stopConfirmationTitle,
                message: kind.stopConfirmationMessage
            ) { [weak self] in
                Task { @MainActor in
                    await self?.stopArchiving(withID: archiveID)
                }
            }
        )
    }

    @MainActor
    private func startArchiving() async {
        do {
            _ = try await startArchivingUseCase(
                .init(sessionKey: sessionKeyProvider.sessionKey, kind: kind))
        } catch {
        }
    }

    @MainActor
    private func stopArchiving(withID id: String) async {
        do {
            try await stopArchivingUseCase(
                .init(sessionKey: sessionKeyProvider.sessionKey, archiveID: id, kind: kind))
        } catch {
        }
    }
}
