//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERAConfiguration

public class MeetingRoomFactory {
    private let baseURL: URL
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let sessionRepository: SessionRepository
    private let publisherRepository: PublisherRepository
    private let roomCredentialsRepository: RoomCredentialsRepository
    private let appConfig: AppConfig

    public init(
        baseURL: URL,
        appConfig: AppConfig,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        sessionRepository: SessionRepository,
        publisherRepository: PublisherRepository,
        roomCredentialsRepository: RoomCredentialsRepository
    ) {
        self.baseURL = baseURL
        self.appConfig = appConfig
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.sessionRepository = sessionRepository
        self.publisherRepository = publisherRepository
        self.roomCredentialsRepository = roomCredentialsRepository
    }

    public func make(
        roomName: RoomName,
        onShowChat: @escaping () -> Void = {},
        onBack: @escaping () -> Void = {},
        onNext: @escaping () -> Void = {},
    ) -> (view: some View, viewModel: MeetingRoomViewModel) {
        let viewModel = MeetingRoomViewModel(
            roomName: roomName,
            baseURL: baseURL,
            connectToRoomUseCase: DefaultConnectToRoomUseCase(
                sessionRepository: sessionRepository,
                roomCredentialsRepository: roomCredentialsRepository),
            disconnectRoomUseCase: DefaultDisconnectRoomUseCase(
                sessionRepository: sessionRepository),
            checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase(),
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            requestMicrophonePermissionUseCase: DefaultRequestMicrophonePermissionUseCase(),
            requestCameraPermissionUseCase: DefaultRequestCameraPermissionUseCase(),
            currentCallParticipantsRepository: currentCallParticipantsRepository,
            appConfig: appConfig,
            meetingRoomNavigation: .init(onBack: onBack, onShowChat: onShowChat, onNext: onNext))
        return (MeetingRoomScreen(viewModel: viewModel), viewModel)
    }

    @MainActor
    public func make(viewModel: MeetingRoomViewModel) -> some View {
        MeetingRoomScreen(viewModel: viewModel)
    }
}
