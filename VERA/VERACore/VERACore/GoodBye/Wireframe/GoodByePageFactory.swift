//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

public class GoodByePageFactory {
    private let joinRoomUseCase: JoinRoomUseCase
    private let userRepository: UserRepository
    private let archivesRepository: ArchivesRepository

    public init(
        joinRoomUseCase: JoinRoomUseCase,
        userRepository: UserRepository,
        archivesRepository: ArchivesRepository
    ) {
        self.joinRoomUseCase = joinRoomUseCase
        self.userRepository = userRepository
        self.archivesRepository = archivesRepository
    }

    public func make(
        roomName: RoomName,
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) -> some View {
        let viewModel = GoodByeViewModel(
            roomName: roomName,
            joinRoomUseCase: joinRoomUseCase,
            userRepository: userRepository,
            archivesRepository: archivesRepository)

        return GoodByeViewScreen(
            viewModel: viewModel,
            onReenter: {
                Task { @MainActor in
                    await viewModel.joinRoom()
                    onReenter()
                }
            },
            onReturnToLanding: onReturnToLanding
        )
        .task {
            await viewModel.setupUI()
        }
    }
}
