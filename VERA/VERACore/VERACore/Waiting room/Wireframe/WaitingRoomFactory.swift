//
//  Created by Vonage on 14/7/25.
//

import SwiftUI
import VERADomain
import VERACommonUI

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
        onActionHandler: @escaping ActionHandler
    ) -> (some View, viewModel: WaitingRoomViewModel) {
        let viewModel = WaitingRoomViewModel(
            roomName: roomName,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            cameraDevicesRepository: cameraDevicesRepository,
            joinRoomUseCase: .init(
                userRepository: userRepository,
                cameraPreviewProviderRepository: cameraPreviewProviderRepository,
                publisherRepository: publisherRepository),
            requestMicrophonePermissionUseCase: DefaultRequestMicrophonePermissionUseCase(),
            requestCameraPermissionUseCase: DefaultRequestCameraPermissionUseCase(),
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase(),
            userRepository: userRepository,
            waitinRoomNavigation: WaitinRoomNavigation(actionHandler: onActionHandler, roomName: roomName))
        return (make(viewModel: viewModel), viewModel)
    }

    @MainActor
    public func make(viewModel: WaitingRoomViewModel) -> some View {
        WaitingRoomScreen(viewModel: viewModel)
    }
}
