//
//  Created by Vonage on 23/7/25.
//

import Combine
import SwiftUI
import VERACommonUI
import VERADomain

public class MeetingRoomFactory {
    private let baseURL: URL
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let sessionRepository: SessionRepository
    private let publisherRepository: PublisherRepository
    private let roomCredentialsRepository: RoomCredentialsRepository
    private let captionsStatusDataSource: CaptionsStatusDataSource
    private let noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource
    private let pinnedParticipantsDataSource: PinnedParticipantsDataSource
    private let configuration: MeetingRoomConfiguration
    private let sessionKeyHolder: SessionKeyHolder

    public init(
        baseURL: URL,
        configuration: MeetingRoomConfiguration,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        sessionRepository: SessionRepository,
        publisherRepository: PublisherRepository,
        roomCredentialsRepository: RoomCredentialsRepository,
        captionsStatusDataSource: CaptionsStatusDataSource,
        noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource,
        pinnedParticipantsDataSource: PinnedParticipantsDataSource,
        sessionKeyHolder: SessionKeyHolder
    ) {
        self.baseURL = baseURL
        self.configuration = configuration
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.sessionRepository = sessionRepository
        self.publisherRepository = publisherRepository
        self.roomCredentialsRepository = roomCredentialsRepository
        self.captionsStatusDataSource = captionsStatusDataSource
        self.noiseSuppressionStatusDataSource = noiseSuppressionStatusDataSource
        self.pinnedParticipantsDataSource = pinnedParticipantsDataSource
        self.sessionKeyHolder = sessionKeyHolder
    }

    @MainActor
    public func make(
        roomName: RoomName,
        getExternalButtons: @escaping () -> [BottomBarButton],
        externalButtonsUpdates: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        onActionHandler: @escaping ActionHandler
    ) -> (view: some View, viewModel: MeetingRoomViewModel) {
        let viewModel = MeetingRoomViewModel(
            roomName: roomName,
            baseURL: baseURL,
            connectToRoomUseCase: DefaultConnectToRoomUseCase(
                sessionRepository: sessionRepository,
                roomCredentialsRepository: roomCredentialsRepository,
                sessionKeyWriter: sessionKeyHolder
            ),
            connectWithSessionKeyUseCase: DefaultConnectWithSessionKeyUseCase(
                sessionRepository: sessionRepository,
                roomCredentialsRepository: roomCredentialsRepository,
                sessionKeyWriter: sessionKeyHolder
            ),
            disconnectRoomUseCase: DefaultDisconnectRoomUseCase(sessionRepository: sessionRepository),
            checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase(),
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            currentCallParticipantsRepository: currentCallParticipantsRepository,
            captionsStatusDataSource: captionsStatusDataSource,
            configuration: configuration,
            meetingRoomNavigation: MeetingRoomNavigation(actionHandler: onActionHandler, roomName: roomName),
            getExternalButtons: getExternalButtons,
            externalButtonsUpdates: externalButtonsUpdates,
            noiseSuppressionStatusDataSource: noiseSuppressionStatusDataSource,
            pinnedParticipantsDataSource: pinnedParticipantsDataSource
        )
        return (make(viewModel: viewModel), viewModel)
    }

    @MainActor
    public func make(viewModel: MeetingRoomViewModel) -> some View {
        MeetingRoomScreen(viewModel: viewModel)
    }
}
