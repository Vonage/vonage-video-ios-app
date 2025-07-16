//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

public class WaitingRoomFactory {

    private let publisherFactory: PublisherFactory
    private let audioDevicesRepository: AudioDevicesRepository

    public init(
        publisherFactory: PublisherFactory,
        audioDevicesRepository: AudioDevicesRepository
    ) {
        self.publisherFactory = publisherFactory
        self.audioDevicesRepository = audioDevicesRepository
    }

    public func make(
        roomName: RoomName,
        onNavigateToRoom: @escaping (RoomName) -> Void
    ) -> some View {
        WaitingRoomScreen(
            viewModel: .init(
                roomName: roomName,
                createPublisherUseCase: .init(publisherFactory: publisherFactory),
                audioDevicesRepository: audioDevicesRepository),
            onNavigateToRoom: onNavigateToRoom
        )
    }
}
