//
//  Created by Vonage on 13/1/26.
//

import Foundation
import VERADomain

public final class ArchiveButtonViewModel: ObservableObject {
    @MainActor @Published public var state = ArchiveButtonState.initial

    private let roomName: RoomName
    private var archiveID: String?
    private let startArchivingUseCase: StartArchivingUseCase
    private let stopArchivingUseCase: StopArchivingUseCase

    public init(
        roomName: RoomName,
        startArchivingUseCase: StartArchivingUseCase,
        stopArchivingUseCase: StopArchivingUseCase
    ) {
        self.roomName = roomName
        self.startArchivingUseCase = startArchivingUseCase
        self.stopArchivingUseCase = stopArchivingUseCase
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
            state = .init(isArchiving: true)
        } catch {
            state = .init(isArchiving: false)
        }
    }

    @MainActor
    private func stopArchiving(withID id: String) async {
        do {
            try await stopArchivingUseCase(.init(roomName: roomName, archiveID: id))
            state = .init(isArchiving: false)
            archiveID = nil
        } catch {
        }
    }
}
