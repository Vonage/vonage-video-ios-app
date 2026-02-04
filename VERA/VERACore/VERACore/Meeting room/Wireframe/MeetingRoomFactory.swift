//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI
import VERAConfiguration
import VERADomain

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

    @MainActor
    public func make(
        roomName: RoomName,
        getExternalButtons: @escaping (MeetingRoomButtonsState) -> [BottomBarButton],
        onActionHandler: @escaping ActionHandler
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
            currentCallParticipantsRepository: currentCallParticipantsRepository,
            appConfig: appConfig,
            meetingRoomNavigation: MeetingRoomNavigation(actionHandler: onActionHandler, roomName: roomName),
            getExternalButtons: getExternalButtons)
        return (make(viewModel: viewModel), viewModel)
    }

    @MainActor
    public func make(viewModel: MeetingRoomViewModel) -> some View {
        MeetingRoomScreen(viewModel: viewModel)
    }
}
