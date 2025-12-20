//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

public class GoodByePageFactory {
    private let joinRoomUseCase: JoinRoomUseCase
    private let userRepository: UserRepository
    private let archivesRepository: ArchivesRepository
    private let archiveRecordingsRepository: ArchiveRecordingsRepository

    public init(
        joinRoomUseCase: JoinRoomUseCase,
        userRepository: UserRepository,
        archivesRepository: ArchivesRepository,
        archiveRecordingsRepository: ArchiveRecordingsRepository
    ) {
        self.joinRoomUseCase = joinRoomUseCase
        self.userRepository = userRepository
        self.archivesRepository = archivesRepository
        self.archiveRecordingsRepository = archiveRecordingsRepository
    }

    public func make(
        roomName: RoomName,
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void,
        onPlay: @escaping (ArchiveRecording) -> Void
    ) -> (view: some View, viewModel: GoodByeViewModel) {
        let viewModel = GoodByeViewModel(
            roomName: roomName,
            joinRoomUseCase: joinRoomUseCase,
            userRepository: userRepository,
            archivesRepository: archivesRepository,
            playRecordingUseCase: .init(
                archiveRecordingsRepository: archiveRecordingsRepository,
                onPlay: onPlay),
            goodByeNavigation: .init(
                onReenter: onReenter,
                onReturnToLanding: onReturnToLanding))
        return (
            GoodByeViewScreen(viewModel: viewModel)
                .task {
                    await viewModel.setupUI()
                }, viewModel
        )
    }

    public func make(viewModel: GoodByeViewModel) -> some View {
        GoodByeViewScreen(viewModel: viewModel)
    }
}
