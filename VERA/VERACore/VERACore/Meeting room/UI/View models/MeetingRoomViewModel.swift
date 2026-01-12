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

public struct MeetingRoomNavigation {
    public let onBack: () -> Void
    public let onShowChat: () -> Void
    public let onNext: () -> Void

    public init(
        onBack: @escaping () -> Void,
        onShowChat: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.onBack = onBack
        self.onShowChat = onShowChat
        self.onNext = onNext
    }
}

public final class MeetingRoomViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let connectToRoomUseCase: ConnectToRoomUseCase
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let disconnectRoomUseCase: DisconnectRoomUseCase
    private let checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase
    private let checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase
    private let requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase
    private let requestCameraPermissionUseCase: RequestCameraPermissionUseCase
    private let appConfig: AppConfig
    private let meetingRoomNavigation: MeetingRoomNavigation

    @MainActor @Published public var state: MeetingRoomViewState = .loading
    @MainActor @Published public var error: AlertItem?
    @MainActor @Published public var toast: ToastItem?

    private let layoutPublisher = CurrentValueSubject<MeetingRoomLayout, Never>(MeetingRoomLayout.activeSpeaker)
    private let sessionStatePublisher = CurrentValueSubject<SessionState, Never>(SessionState.initial)
    private let callStatePublisher = CurrentValueSubject<CallState, Never>(CallState.idle)

    public weak var currentCall: CallFacade?

    public let roomName: RoomName
    public let baseURL: URL
    private var initialised = false
    private static let disconnectionTimeoutInNanoseconds: UInt64 = 1_000_000_000 * 6

    public init(
        roomName: RoomName,
        baseURL: URL,
        connectToRoomUseCase: ConnectToRoomUseCase,
        disconnectRoomUseCase: DisconnectRoomUseCase,
        checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase,
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase,
        requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase,
        requestCameraPermissionUseCase: RequestCameraPermissionUseCase,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        appConfig: AppConfig,
        meetingRoomNavigation: MeetingRoomNavigation
    ) {
        self.roomName = roomName
        self.baseURL = baseURL
        self.connectToRoomUseCase = connectToRoomUseCase
        self.disconnectRoomUseCase = disconnectRoomUseCase
        self.checkMicrophoneAuthorizationStatusUseCase = checkMicrophoneAuthorizationStatusUseCase
        self.checkCameraAuthorizationStatusUseCase = checkCameraAuthorizationStatusUseCase
        self.requestMicrophonePermissionUseCase = requestMicrophonePermissionUseCase
        self.requestCameraPermissionUseCase = requestCameraPermissionUseCase
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.appConfig = appConfig
        self.meetingRoomNavigation = meetingRoomNavigation
    }

    public func loadUI() {
        guard !initialised else { return }
        initialised = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            state = .loading

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

                call.eventsPublisher
                    .sink { [weak self] event in
                        Task { @MainActor in
                            switch event {
                            case .didBeginReconnecting:
                                self?.toast =
                                    .init(message: "Session did drop, started reconnection", mode: .warning)
                            case .didReconnect:
                                self?.toast =
                                    .init(message: "Session did reconnect", mode: .info)
                            case .error(let error):
                                self?.toast =
                                    .init(message: error.localizedDescription, mode: .failure)
                            case .sessionFailure(let error):
                                self?.toast =
                                    .init(message: error.localizedDescription, mode: .failure)

                            case .disconnected:
                                self?.toast =
                                    .init(message: "Session did disconnect", mode: .failure)

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
                    .store(in: &cancellables)

                self.currentCall = call
            } catch {
                await MainActor.run { [weak self] in
                    self?.error = AlertItem.genericError(
                        error.localizedDescription
                    ) { [weak self] in
                        self?.meetingRoomNavigation.onBack()
                    }
                }
            }
        }
    }

    func navigateBackIfNeeded(_ callState: CallState) {
        guard callState == .disconnected else { return }
        Task { @MainActor [weak self] in
            self?.meetingRoomNavigation.onNext()
        }
    }

    func observeSessionState(_ participantsPublisher: AnyPublisher<ParticipantsState, Never>) {
        Publishers.CombineLatest4(
            participantsPublisher
                .removeDuplicates(),
            sessionStatePublisher,
            layoutPublisher,
            callStatePublisher
        )
        .map { [weak self] participantsState, sessionState, layout, callState in
            guard let self else { return MeetingRoomState.initial }

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

            return MeetingRoomState(
                roomName: self.roomName,
                roomURL: baseURL.appendingPathComponent(roomName),
                isMicEnabled: sessionState.isPublishingAudio && checkMicrophoneAuthorizationStatusUseCase(),
                isCameraEnabled: sessionState.isPublishingVideo && checkCameraAuthorizationStatusUseCase(),
                participants: sortedPaticipants,
                layout: layout,
                activeSpeakerId: participantsState.activeParticipantId,
                showChatButton: appConfig.meetingRoomSettings.allowChat,
                allowMicrophoneControl: appConfig.audioSettings.allowMicrophoneControl,
                allowCameraControl: appConfig.videoSettings.allowCameraControl,
                showParticipantList: appConfig.meetingRoomSettings.showParticipantList,
                callState: callState)
        }
        .removeDuplicates()
        .sink { [weak self] newState in
            Task { @MainActor in
                self?.state = .content(newState)
            }
        }
        .store(in: &cancellables)
    }

    public func onToggleMic() {
        if !checkMicrophoneAuthorizationStatusUseCase() {
            Task {
                await requestMicrophonePermissionUseCase()
            }
            return
        }
        currentCall?.toggleLocalAudio()
    }

    public func onToggleCamera() {
        if !checkCameraAuthorizationStatusUseCase() {
            Task {
                await requestCameraPermissionUseCase()
            }
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
        Task { @MainActor [weak self] in
            do {
                try await self?.disconnectRoomUseCase()
            } catch CallError.callNotConnected {
                // Wait until the call connects instead of showing an error
            } catch {
                await MainActor.run { [weak self] in
                    self?.error = AlertItem.genericError(error.localizedDescription)
                }
            }
        }
    }

    public func showChat() {
        meetingRoomNavigation.onShowChat()
    }
}
