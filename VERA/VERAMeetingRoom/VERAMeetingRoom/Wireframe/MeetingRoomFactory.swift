//
//  Created by Vonage on 23/7/25.
//

import Combine
import SwiftUI
import VERACommonUI
import VERADomain

/// Factory that wires the meeting room view and view model.
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

    /// Creates a meeting room factory with its required dependencies.
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

    /// Creates a meeting room view and view model for the supplied room.
    ///
    /// - Parameters:
    ///   - roomName: Room name to join.
    ///   - uiProvider: Provider used for host-driven bottom bar customization.
    ///   - onActionHandler: Handler for navigation and alert actions emitted by the meeting room.
    /// - Returns: The constructed meeting room view and its view model.
    @MainActor
    public func make(
        roomName: RoomName,
        uiProvider: any MeetingRoomUIProvider = DefaultMeetingRoomUIProvider(),
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
            disconnectRoomUseCase: DefaultDisconnectRoomUseCase(sessionRepository: sessionRepository),
            checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase(),
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            currentCallParticipantsRepository: currentCallParticipantsRepository,
            captionsStatusDataSource: captionsStatusDataSource,
            configuration: configuration,
            meetingRoomNavigation: MeetingRoomNavigation(actionHandler: onActionHandler, roomName: roomName),
            uiProvider: uiProvider,
            noiseSuppressionStatusDataSource: noiseSuppressionStatusDataSource,
            pinnedParticipantsDataSource: pinnedParticipantsDataSource
        )
        return (make(viewModel: viewModel, uiProvider: uiProvider), viewModel)
    }

    /// Creates a meeting room using legacy external button closures.
    ///
    /// Prefer `make(roomName:uiProvider:onActionHandler:)` so hosts can provide
    /// additive bottom bar buttons and optional custom bottom bar content from a
    /// single provider object.
    @available(*, deprecated, message: "Use make(roomName:uiProvider:onActionHandler:) instead.")
    @MainActor
    public func make(
        roomName: RoomName,
        getExternalButtons: @escaping @MainActor () -> [BottomBarButton],
        externalButtonsUpdates: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        onActionHandler: @escaping ActionHandler
    ) -> (view: some View, viewModel: MeetingRoomViewModel) {
        make(
            roomName: roomName,
            uiProvider: DefaultMeetingRoomUIProvider(
                bottomBarButtons: getExternalButtons,
                updates: externalButtonsUpdates
            ),
            onActionHandler: onActionHandler
        )
    }

    /// Creates a meeting room screen for an existing view model using the default UI provider.
    @MainActor
    public func make(viewModel: MeetingRoomViewModel) -> some View {
        make(viewModel: viewModel, uiProvider: DefaultMeetingRoomUIProvider())
    }

    /// Creates a meeting room screen for an existing view model and UI provider.
    ///
    /// Use this overload when tests or composition roots already own the view model
    /// but still need to pass custom bottom bar rendering through the SwiftUI layer.
    @MainActor
    public func make(
        viewModel: MeetingRoomViewModel,
        uiProvider: any MeetingRoomUIProvider
    ) -> some View {
        MeetingRoomScreen(viewModel: viewModel, uiProvider: uiProvider)
    }
}
