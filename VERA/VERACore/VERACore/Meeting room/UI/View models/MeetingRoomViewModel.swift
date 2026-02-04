//
//  Created by Vonage on 23/7/25.
//

import Combine
import Foundation
import VERAConfiguration
import VERADomain

public enum MeetingRoomViewState: Equatable {
    case loading
    case content(MeetingRoomState)
}

public struct MeetingRoomButtonsState {
    public let archivingState: ArchivingState

    public init(archivingState: ArchivingState) {
        self.archivingState = archivingState
    }
}

public final class MeetingRoomViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let connectToRoomUseCase: ConnectToRoomUseCase
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let disconnectRoomUseCase: DisconnectRoomUseCase
    private let checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase
    private let checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase
    private let appConfig: AppConfig
    private let meetingRoomNavigation: MeetingRoomDestination

    @MainActor @Published public var state: MeetingRoomViewState = .loading
    @MainActor @Published public var toast: ToastItem?
    @MainActor @Published public var extraButtons: [BottomBarButton] = []
    @MainActor @Published public var extraTopTrailingButtons: [ViewGenerator] = []
    @MainActor @Published public var isArchiving = false

    private let layoutPublisher = CurrentValueSubject<MeetingRoomLayout, Never>(MeetingRoomLayout.activeSpeaker)
    private let sessionStatePublisher = CurrentValueSubject<SessionState, Never>(SessionState.initial)
    private let callStatePublisher = CurrentValueSubject<CallState, Never>(CallState.idle)
    private let archivingPublisher = CurrentValueSubject<ArchivingState, Never>(ArchivingState.idle)

    public weak var currentCall: CallFacade?

    public let roomName: RoomName
    public let baseURL: URL
    private var initialised = false
    private static let disconnectionTimeoutInNanoseconds: UInt64 = 1_000_000_000 * 6
    private var getExternalButtons: (MeetingRoomButtonsState) -> [BottomBarButton]

    public init(
        roomName: RoomName,
        baseURL: URL,
        connectToRoomUseCase: ConnectToRoomUseCase,
        disconnectRoomUseCase: DisconnectRoomUseCase,
        checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase,
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        appConfig: AppConfig,
        meetingRoomNavigation: MeetingRoomDestination,
        getExternalButtons: @escaping (MeetingRoomButtonsState) -> [BottomBarButton]
    ) {
        self.roomName = roomName
        self.baseURL = baseURL
        self.connectToRoomUseCase = connectToRoomUseCase
        self.disconnectRoomUseCase = disconnectRoomUseCase
        self.checkMicrophoneAuthorizationStatusUseCase = checkMicrophoneAuthorizationStatusUseCase
        self.checkCameraAuthorizationStatusUseCase = checkCameraAuthorizationStatusUseCase
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.appConfig = appConfig
        self.meetingRoomNavigation = meetingRoomNavigation
        self.getExternalButtons = getExternalButtons
    }

    @MainActor
    public func loadUI() async {
        guard !initialised else { return }
        initialised = true

        await addObservers()

        updateExtraButtons()
    }

    public func onToggleMic() {
        if checkMicrophoneAuthorizationStatusUseCase().isDenied {
            meetingRoomNavigation.presentMicrophonePermissionAlert()
            return
        }
        currentCall?.toggleLocalAudio()
    }

    public func onToggleCamera() {
        if checkCameraAuthorizationStatusUseCase().isDenied {
            meetingRoomNavigation.presentCameraPermissionAlert()
            return
        }
        currentCall?.toggleLocalVideo()
    }

    public func onCameraSwitch() {
        currentCall?.toggleLocalCamera()
    }

    public func onToggleLayout() {
        let newLayout: MeetingRoomLayout =
            switch layoutPublisher.value {
            case .grid: .activeSpeaker
            case .activeSpeaker: .grid
            }
        layoutPublisher.value = newLayout
    }

    public func endCall() {
        Task { @MainActor in
            do {
                try await disconnectRoomUseCase()
            } catch CallError.callNotConnected {
                // Wait until the call connects instead of showing an error
            } catch {
                await MainActor.run { [weak self] in
                    self?.meetingRoomNavigation.presentAlertError(with: error.localizedDescription, shouldBack: false)
                }
            }
        }
    }
}

extension MeetingRoomViewModel {

    fileprivate func navigateBackIfNeeded(_ callState: CallState) {
        guard callState == .disconnected else { return }
        Task { @MainActor [weak self] in
            self?.meetingRoomNavigation.onNext()
        }
    }

    fileprivate func observeSessionState(_ participantsPublisher: AnyPublisher<ParticipantsState, Never>) {
        let sortedParticipantsPublisher = Publishers.CombineLatest(
            participantsPublisher.removeDuplicates(), layoutPublisher
        ).map { participantsState, layout in
            var sortedPaticipants = participantsState.participants
            if layout == .activeSpeaker {
                sortedPaticipants = sortedPaticipants.sortedByDisplayPriority(
                    activeSpeakerId: participantsState.activeParticipantId)
                if let localParticipant = participantsState.localParticipant {
                    if sortedPaticipants.isEmpty {
                        sortedPaticipants.append(localParticipant)
                    } else {
                        sortedPaticipants.insert(localParticipant, at: 1)
                    }
                }
            } else {
                sortedPaticipants = sortedPaticipants.sortedByCreationDate()
                if let localParticipant = participantsState.localParticipant {
                    if sortedPaticipants.isEmpty {
                        sortedPaticipants.append(localParticipant)
                    } else {
                        sortedPaticipants.insert(localParticipant, at: 0)
                    }
                }
            }
            return MeetingRoomParticipantsState(
                participants: sortedPaticipants,
                layout: layout,
                activeSpeakerId: participantsState.activeParticipantId)
        }

        Publishers.CombineLatest4(
            sortedParticipantsPublisher,
            sessionStatePublisher,
            callStatePublisher,
            archivingPublisher
        )
        .map { [weak self] participantsState, sessionState, callState, archivingState in
            guard let self else { return MeetingRoomState.initial }
            return MeetingRoomState(
                roomName: self.roomName,
                roomURL: baseURL.meetingRoomURL(roomName),
                isMicEnabled: sessionState.isPublishingAudio
                    && checkMicrophoneAuthorizationStatusUseCase().isAuthorized,
                isCameraEnabled: sessionState.isPublishingVideo && checkCameraAuthorizationStatusUseCase().isAuthorized,
                participants: participantsState.participants,
                layout: participantsState.layout,
                activeSpeakerId: participantsState.activeSpeakerId,
                allowMicrophoneControl: appConfig.audioSettings.allowMicrophoneControl,
                allowCameraControl: appConfig.videoSettings.allowCameraControl,
                showParticipantList: appConfig.meetingRoomSettings.showParticipantList,
                callState: callState,
                archivingState: archivingState)
        }
        .removeDuplicates()
        .sink { [weak self] newState in
            Task { @MainActor in
                self?.state = .content(newState)
            }
        }
        .store(in: &cancellables)
    }

    fileprivate func addObservers() async {
        do {
            let call = try await connectToRoomUseCase(roomName: roomName)
            observeSessionState(call.participantsPublisher)

            call.statePublisher
                .sink { [weak self] state in
                    self?.sessionStatePublisher.send(state)
                }
                .store(in: &cancellables)

            call.callState
                .sink { [weak self] callState in
                    self?.callStatePublisher.send(callState)
                    self?.navigateBackIfNeeded(callState)
                }
                .store(in: &cancellables)

            call.archivingState
                .dropFirst()
                .sink { [weak self] archivingState in
                    self?.handleArchivingStateChange(archivingState)
                }
                .store(in: &cancellables)

            call.eventsPublisher
                .sink { [weak self] event in
                    self?.handleEvents(event)
                }
                .store(in: &cancellables)

            self.currentCall = call
        } catch {
            await MainActor.run { [weak self] in
                self?.meetingRoomNavigation.presentAlertError(with: error.localizedDescription, shouldBack: true)
            }
        }
    }

    fileprivate func handleArchivingStateChange(_ archivingState: ArchivingState) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.archivingPublisher.value = archivingState
            switch archivingState {
            case .idle:
                self.toast = .init(message: "Session recording stopped", mode: .info)
            case .archiving:
                self.toast = .init(message: "Session recording started", mode: .info)
            }

            self.updateArchivingButtons()
        }
    }

    fileprivate func handleEvents(_ event: SessionEvent) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch event {
            case .didBeginReconnecting:
                self.toast = .init(message: "Session did drop, started reconnection", mode: .warning)
            case .didReconnect:
                self.toast = .init(message: "Session did reconnect", mode: .info)
            case .error(let error):
                self.toast = .init(message: error.localizedDescription, mode: .failure)
            case .sessionFailure(let error):
                self.toast = .init(message: error.localizedDescription, mode: .failure)
            case .disconnected:
                self.toast = .init(message: "Session did disconnect", mode: .failure)

                Task { [weak self] in
                    try? await Task.sleep(
                        nanoseconds: MeetingRoomViewModel.disconnectionTimeoutInNanoseconds)
                    try? await self?.disconnectRoomUseCase()
                }
            default:
                break
            }
        }
    }

    @MainActor
    fileprivate func updateExtraButtons() {
        updateArchivingButtons()
    }

    @MainActor
    fileprivate func updateArchivingButtons() {
        let archivingState = self.archivingPublisher.value
        self.extraButtons = self.getExternalButtons(.init(archivingState: archivingState))
    }
}
