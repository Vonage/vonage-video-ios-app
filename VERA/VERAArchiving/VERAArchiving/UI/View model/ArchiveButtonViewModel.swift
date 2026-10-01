//
//  Created by Vonage on 13/1/26.
//

import Combine
import Foundation
import Observation
import VERADomain

@Observable
public final class ArchiveButtonViewModel {
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    public var state: ArchivingState = .idle

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
        sessionKeyProvider: SessionKeyProvider,
        startArchivingUseCase: StartArchivingUseCase,
        stopArchivingUseCase: StopArchivingUseCase,
        archivingStatusDataSource: ArchivingStatusDataSource,
        showAlert: @escaping (AlertItem) -> Void
    ) {
        self.sessionKeyProvider = sessionKeyProvider
        self.startArchivingUseCase = startArchivingUseCase
        self.stopArchivingUseCase = stopArchivingUseCase
        self.archivingStatusDataSource = archivingStatusDataSource
        self.showAlert = showAlert
    }

    public func setup() {
        guard !initiated else { return }
        initiated = true

        archivingStatusDataSource.archivingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.state = status
            }
            .store(in: &cancellables)
    }

    public func onTap() {
        switch state {
        case .archiving(let archiveID):
            showStopRecordingConfirmation(archiveID: archiveID)
        case .idle:
            showStartRecordingConfirmation()
        }
    }

    private func showStartRecordingConfirmation() {
        showAlert(
            AlertItem(
                title: String(localized: "Start Recording?", bundle: .veraArchiving),
                message:
                    String(
                        localized: "start.recording.message",
                        bundle: .veraArchiving)
            ) { [weak self] in
                Task { @MainActor in
                    await self?.startArchiving()
                }
            }
        )
    }

    private func showStopRecordingConfirmation(archiveID: String) {
        showAlert(
            AlertItem(
                title:
                    String(localized: "Stop Recording?", bundle: .veraArchiving),
                message:
                    String(localized: "stop.recording.message", bundle: .veraArchiving)
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
            _ = try await startArchivingUseCase(.init(sessionKey: sessionKeyProvider.sessionKey))
        } catch {
        }
    }

    @MainActor
    private func stopArchiving(withID id: String) async {
        do {
            try await stopArchivingUseCase(.init(sessionKey: sessionKeyProvider.sessionKey, archiveID: id))
        } catch {
        }
    }
}
