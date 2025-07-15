//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

public class WaitingRoomFactory {

    private let publisherFactory: PublisherFactory

    public init(publisherFactory: PublisherFactory) {
        self.publisherFactory = publisherFactory
    }

    public func make(
        roomName: RoomName,
        onNavigateToRoom: @escaping (RoomName) -> Void
    ) -> some View {
        WaitingRoomScreen(
            viewModel: .init(
                roomName: roomName,
                createPublisherUseCase: .init(publisherFactory: publisherFactory)),
            onNavigateToRoom: onNavigateToRoom
        )
    }
}
