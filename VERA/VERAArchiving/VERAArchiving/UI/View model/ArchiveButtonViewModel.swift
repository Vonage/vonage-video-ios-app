//
//  Created by Vonage on 13/1/26.
//

import Combine
import Foundation
import VERADomain

public final class ArchiveButtonViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @MainActor @Published public var state = ArchiveButtonState.idle

    private let roomName: RoomName
    private var archiveID: String?
    private let startArchivingUseCase: StartArchivingUseCase
    private let stopArchivingUseCase: StopArchivingUseCase
    private let archivingStatusDataSource: ArchivingStatusDataSource
    private var initiated = false

    public init(
        roomName: RoomName,
        startArchivingUseCase: StartArchivingUseCase,
        stopArchivingUseCase: StopArchivingUseCase,
        archivingStatusDataSource: ArchivingStatusDataSource
    ) {
        self.roomName = roomName
        self.startArchivingUseCase = startArchivingUseCase
        self.stopArchivingUseCase = stopArchivingUseCase
        self.archivingStatusDataSource = archivingStatusDataSource
    }

    public func setup() {
        guard !initiated else { return }
        initiated = true

        archivingStatusDataSource.archivingStatus()
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    self?.state = status ? .archiving : .idle
                }
            }
            .store(in: &cancellables)
    }

    public func onTap() {
        Task { @MainActor in
            if let archiveID = archiveID, state.isArchiving {
                await stopArchiving(withID: archiveID)
            } else {
                await startArchiving()
            }
        }
    }

    @MainActor
    private func startArchiving() async {
        do {
            archiveID = try await startArchivingUseCase(.init(roomName: roomName))
        } catch {
        }
    }

    @MainActor
    private func stopArchiving(withID id: String) async {
        do {
            try await stopArchivingUseCase(.init(roomName: roomName, archiveID: id))
            archiveID = nil
        } catch {
        }
    }
}
