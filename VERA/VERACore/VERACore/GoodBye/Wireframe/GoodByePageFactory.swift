//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERADomain

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

    public func make<ContentView: View>(
        roomName: RoomName,
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void,
        @ViewBuilder additionalContentView: @escaping () -> ContentView
    ) -> (view: some View, viewModel: GoodByeViewModel) {
        let viewModel = GoodByeViewModel(
            roomName: roomName,
            joinRoomUseCase: joinRoomUseCase,
            userRepository: userRepository,
            goodByeNavigation: .init(
                onReenter: onReenter,
                onReturnToLanding: onReturnToLanding))
        return (
            GoodByeViewScreen(
                viewModel: viewModel, additionalContentView: additionalContentView),
            viewModel
        )
    }

    public func make<ContentView: View>(
        viewModel: GoodByeViewModel,
        @ViewBuilder additionalContentView: @escaping () -> ContentView
    ) -> some View {
        GoodByeViewScreen(viewModel: viewModel, additionalContentView: additionalContentView)
    }
}
