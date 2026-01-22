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

        archivingStatusDataSource.archivingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.state = status
            }
            .store(in: &cancellables)
    }

    public func onTap() {
        Task { @MainActor in
            switch state {
            case .archiving(let archiveID):
                await stopArchiving(withID: archiveID)
            case .idle:
                await startArchiving()
            }
        }
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
