//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

public class WaitingRoomFactory {

    private let publisherRepository: PublisherRepository
    private let cameraPreviewProviderRepository: CameraPreviewProviderRepository
    private let audioDevicesRepository: AudioDevicesRepository
    private let cameraDevicesRepository: CameraDevicesRepository
    private let userRepository: UserRepository

    public init(
        publisherRepository: PublisherRepository,
        cameraPreviewProviderRepository: CameraPreviewProviderRepository,
        audioDevicesRepository: AudioDevicesRepository,
        cameraDevicesRepository: CameraDevicesRepository,
        userRepository: UserRepository
    ) {
        self.publisherRepository = publisherRepository
        self.cameraPreviewProviderRepository = cameraPreviewProviderRepository
        self.audioDevicesRepository = audioDevicesRepository
        self.cameraDevicesRepository = cameraDevicesRepository
        self.userRepository = userRepository
    }

    public func make(
        roomName: RoomName,
        onNavigateToRoom: @escaping (RoomName) -> Void
    ) -> some View {
        let viewModel = WaitingRoomViewModel(
            roomName: roomName,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            audioDevicesRepository: audioDevicesRepository,
            cameraDevicesRepository: cameraDevicesRepository,
            selectAudioDeviceUseCase: .init(audioDevicesRepository: audioDevicesRepository),
            joinRoomUseCase: .init(
                userRepository: userRepository,
                cameraPreviewProviderRepository: cameraPreviewProviderRepository,
                publisherRepository: publisherRepository),
            requestMicrophonePermissionUseCase: .init(),
            requestCameraPermissionUseCase: .init(),
            checkCameraAuthorizationStatusUseCase: .init(),
            userRepository: userRepository)
        viewModel.loadUI()
        viewModel.startVideoPreviewIfNeeded()
        return WaitingRoomScreen(
            viewModel: viewModel,
            onNavigateToRoom: onNavigateToRoom
        )
    }
}
