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
        onShowChat: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) -> some View {
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
            currentCallParticipantsRepository: currentCallParticipantsRepository,
            appConfig: appConfig)
        return MeetingRoomScreen(
            viewModel: viewModel,
            onShowChat: onShowChat,
            onBack: onBack)
    }
}
