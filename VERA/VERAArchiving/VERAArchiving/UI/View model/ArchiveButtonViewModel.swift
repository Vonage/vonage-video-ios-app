//
//  Created by Vonage on 13/1/26.
//

import Combine
import Foundation
import VERADomain

public final class ArchiveButtonViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published public var state: ArchivingState = .idle

    private let roomName: RoomName
    private let startArchivingUseCase: StartArchivingUseCase
    private let stopArchivingUseCase: StopArchivingUseCase
    private let archivingStatusDataSource: ArchivingStatusDataSource
    private let showAlert: (AlertItem) -> Void
    private var initiated = false

    public init(
        roomName: RoomName,
        startArchivingUseCase: StartArchivingUseCase,
        stopArchivingUseCase: StopArchivingUseCase,
        archivingStatusDataSource: ArchivingStatusDataSource,
        showAlert: @escaping (AlertItem) -> Void
    ) {
        self.roomName = roomName
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
                        bundle: .veraArchiving),
                onConfirm: { [weak self] in
                    Task { @MainActor in
                        await self?.startArchiving()
                    }
                }
            ))
    }

    private func showStopRecordingConfirmation(archiveID: String) {
        showAlert(
            AlertItem(
                title:
                    String(localized: "Stop Recording?", bundle: .veraArchiving),
                message:
                    String(localized: "stop.recording.message", bundle: .veraArchiving),
                onConfirm: { [weak self] in
                    Task { @MainActor in
                        await self?.stopArchiving(withID: archiveID)
                    }
                }
            ))
    }

    @MainActor
    private func startArchiving() async {
        do {
            _ = try await startArchivingUseCase(.init(roomName: roomName))
        } catch {
        }
    }

    @MainActor
    private func stopArchiving(withID id: String) async {
        do {
            try await stopArchivingUseCase(.init(roomName: roomName, archiveID: id))
        } catch {
        }
    }
}
