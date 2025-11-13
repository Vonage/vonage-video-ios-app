//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public class LandingPageFactory {

    lazy var roomNameGeneratorFactory = RoomNameGeneratorFactory()

    public init() {}

    @MainActor
    public func make(
        onNavigateToWaitingRoom: @escaping (String) -> Void
    ) -> some View {
        LandingPageScreen(
            viewModel: .init(
                tryJoinRoomUseCase: DefaultTryJoinRoomUseCase(),
                tryCreatingANewRoomUseCase: DefaultTryCreatingANewRoomUseCase(
                    roomNameGenerator: roomNameGeneratorFactory.make())),
            onNavigateToWaitingRoom: onNavigateToWaitingRoom)
    }
}
