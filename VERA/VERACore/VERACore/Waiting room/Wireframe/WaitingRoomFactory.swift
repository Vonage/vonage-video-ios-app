//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

public class WaitingRoomFactory {

    private let publisherRepository: PublisherRepository
    private let cameraPreviewProviderRepository: CameraPreviewProviderRepository
    private let cameraDevicesRepository: CameraDevicesRepository
    private let userRepository: UserRepository

    public init(
        publisherRepository: PublisherRepository,
        cameraPreviewProviderRepository: CameraPreviewProviderRepository,
        cameraDevicesRepository: CameraDevicesRepository,
        userRepository: UserRepository
    ) {
        self.publisherRepository = publisherRepository
        self.cameraPreviewProviderRepository = cameraPreviewProviderRepository
        self.cameraDevicesRepository = cameraDevicesRepository
        self.userRepository = userRepository
    }

    @MainActor
    public func make(
        roomName: RoomName,
        onNavigateToRoom: @escaping (RoomName) -> Void
    ) -> some View {
        let viewModel = WaitingRoomViewModel(
            roomName: roomName,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            cameraDevicesRepository: cameraDevicesRepository,
            joinRoomUseCase: .init(
                userRepository: userRepository,
                cameraPreviewProviderRepository: cameraPreviewProviderRepository,
                publisherRepository: publisherRepository),
            requestMicrophonePermissionUseCase: .init(),
            requestCameraPermissionUseCase: .init(),
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            userRepository: userRepository)
        return WaitingRoomScreen(
            viewModel: viewModel,
            onNavigateToRoom: onNavigateToRoom
        )
    }
}
