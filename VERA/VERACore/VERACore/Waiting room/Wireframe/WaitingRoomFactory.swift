//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

public class WaitingRoomFactory {

    private let publisherRepository: PublisherRepository
    private let audioDevicesRepository: AudioDevicesRepository
    private let cameraDevicesRepository: CameraDevicesRepository
    private let userRepository: UserRepository

    public init(
        publisherRepository: PublisherRepository,
        audioDevicesRepository: AudioDevicesRepository,
        cameraDevicesRepository: CameraDevicesRepository,
        userRepository: UserRepository
    ) {
        self.publisherRepository = publisherRepository
        self.audioDevicesRepository = audioDevicesRepository
        self.cameraDevicesRepository = cameraDevicesRepository
        self.userRepository = userRepository
    }

    public func make(
        roomName: RoomName,
        onNavigateToRoom: @escaping (RoomName) -> Void
    ) -> some View {
        WaitingRoomScreen(
            viewModel: .init(roomName: roomName,
                             publisherRepository: publisherRepository,
                             audioDevicesRepository: audioDevicesRepository,
                             cameraDevicesRepository: cameraDevicesRepository,
                             selectAudioDeviceUseCase: .init(audioDevicesRepository: audioDevicesRepository),
                             joinRoomUseCase: .init(userRepository: userRepository,
                                                    publisherRepository: publisherRepository),
                             userRepository: userRepository),
            onNavigateToRoom: onNavigateToRoom
        )
    }
}
