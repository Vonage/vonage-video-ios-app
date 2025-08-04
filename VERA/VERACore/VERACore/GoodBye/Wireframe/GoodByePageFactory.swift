//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

public class GoodByePageFactory {
    private let joinRoomUseCase: JoinRoomUseCase
    private let userRepository: UserRepository

    public init(
        joinRoomUseCase: JoinRoomUseCase,
        userRepository: UserRepository
    ) {
        self.joinRoomUseCase = joinRoomUseCase
        self.userRepository = userRepository
    }

    public func make(
        roomName: RoomName,
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) -> some View {
        let viewModel = GoodByeViewModel(
            roomName: roomName,
            joinRoomUseCase: joinRoomUseCase,
            userRepository: userRepository)

        return GoodByeViewScreen(
            viewModel: viewModel,
            onReenter: {
                Task { @MainActor in
                    await viewModel.joinRoom()
                    onReenter()
                }
            },
            onReturnToLanding: onReturnToLanding)
    }
}
