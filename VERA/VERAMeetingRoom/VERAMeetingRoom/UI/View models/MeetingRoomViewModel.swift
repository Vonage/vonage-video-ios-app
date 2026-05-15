//
//  Created by Vonage on 23/7/25.
//

import Combine
import Foundation
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

public struct MeetingRoomOverlayState {
    public let captions: [CaptionItem]

    public init(captions: [CaptionItem]) {
        self.captions = captions
    }
}

public final class MeetingRoomViewModel: ObservableObject {

    private static let disconnectionTimeoutInSeconds = 6

    private var cancellables = Set<AnyCancellable>()
    private let connectToRoomUseCase: ConnectToRoomUseCase
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let disconnectRoomUseCase: DisconnectRoomUseCase
    private let checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase
    private let checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase
    private let configuration: MeetingRoomConfiguration
    private let meetingRoomNavigation: MeetingRoomDestination
    private let captionsStatusDataSource: CaptionsStatusDataSource
    private let noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource
    private let pinnedParticipantsDataSource: PinnedParticipantsDataSource

    @MainActor @Published public var state: MeetingRoomViewState = .loading
    @MainActor @Published public var toast: ToastItem?
    @MainActor @Published public var extraButtons: [BottomBarButton] = []
    @MainActor @Published public var extraTopTrailingButtons: [ViewGenerator] = []
    @MainActor @Published public var isArchiving = false

    /// Tracks the fallback disconnection task so it can be cancelled on normal call end.
    @MainActor private var disconnectionTask: Task<Void, Never>?

    private let layoutPublisher = CurrentValueSubject<MeetingRoomLayout, Never>(.activeSpeaker)
    private let sessionStatePublisher = CurrentValueSubject<SessionState, Never>(.initial)
    private let callStatePublisher = CurrentValueSubject<CallState, Never>(.idle)
    private let archivingPublisher = CurrentValueSubject<ArchivingState, Never>(.idle)
    private let noiseSuppressionPublisher = CurrentValueSubject<NoiseSuppressionState, Never>(.idle)

    public weak var currentCall: CallFacade?

    public let roomName: RoomName
    public let baseURL: URL
    private var initialised = false
    private var getExternalButtons: (MeetingRoomButtonsState) -> [BottomBarButton]

    public init(
        roomName: RoomName,
        baseURL: URL,
        connectToRoomUseCase: ConnectToRoomUseCase,
        disconnectRoomUseCase: DisconnectRoomUseCase,
        checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase,
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        captionsStatusDataSource: CaptionsStatusDataSource,
        configuration: MeetingRoomConfiguration,
        meetingRoomNavigation: MeetingRoomDestination,
        getExternalButtons: @escaping (MeetingRoomButtonsState) -> [BottomBarButton],
        noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource,
        pinnedParticipantsDataSource: PinnedParticipantsDataSource
    ) {
        self.roomName = roomName
        self.baseURL = baseURL
        self.connectToRoomUseCase = connectToRoomUseCase
        self.disconnectRoomUseCase = disconnectRoomUseCase
        self.checkMicrophoneAuthorizationStatusUseCase = checkMicrophoneAuthorizationStatusUseCase
        self.checkCameraAuthorizationStatusUseCase = checkCameraAuthorizationStatusUseCase
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.configuration = configuration
        self.meetingRoomNavigation = meetingRoomNavigation
        self.getExternalButtons = getExternalButtons
        self.captionsStatusDataSource = captionsStatusDataSource
        self.noiseSuppressionStatusDataSource = noiseSuppressionStatusDataSource
        self.pinnedParticipantsDataSource = pinnedParticipantsDataSource
    }

    @MainActor
    public func loadUI() async {
        guard !initialised else { return }
        initialised = true

        do {
            await MediaPermissions.requestPermissionsIfNeeded()

            let call = try await connect()
            currentCall = call

            await addObservers(call)

            updateExtraButtons()
        } catch {
            await MainActor.run { [weak self] in
                self?.meetingRoomNavigation.presentAlertError(with: error.localizedDescription, shouldBack: true)
            }
        }
    }

    public func onToggleMic() {
        guard checkMicrophoneAuthorizationStatusUseCase().isAuthorized else {
            meetingRoomNavigation.presentMicrophonePermissionAlert()
            return
        }
        currentCall?.toggleLocalAudio()
    }

    public func onToggleCamera() {
        guard checkCameraAuthorizationStatusUseCase().isAuthorized else {
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

    public func onTogglePin(participantId: String) {
        Task {
            await pinnedParticipantsDataSource.togglePin(participantId: participantId)
        }
    }

    public func endCall() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await disconnectRoomUseCase()
            } catch CallError.callNotConnected {
                // Wait until the call connects instead of showing an error
            } catch {
                meetingRoomNavigation.presentAlertError(with: error.localizedDescription, shouldBack: false)
            }
        }
    }
}

extension MeetingRoomViewModel {

    fileprivate func handleNoiseSuppressionChange(_ noiseSuppressionState: NoiseSuppressionState) {
        Task { @MainActor [weak self] in
            self?.noiseSuppressionPublisher.value = noiseSuppressionState
        }
    }

    fileprivate func navigateBackIfNeeded(_ callState: CallState) {
        guard callState == .disconnected else { return }
        Task { @MainActor [weak self] in
            self?.disconnectionTask?.cancel()
            self?.disconnectionTask = nil
            self?.meetingRoomNavigation.onNext()
        }
    }

    fileprivate func observeSessionState(_ participantsPublisher: AnyPublisher<ParticipantsState, Never>) {
        let sortedParticipantsPublisher = Publishers.CombineLatest3(
            participantsPublisher.removeDuplicates(),
            layoutPublisher,
            pinnedParticipantsDataSource.pinnedParticipantIds
        )
        .map { [weak self] participantsState, layout, pinnedIds -> MeetingRoomParticipantsState in
            guard let self else {
                return MeetingRoomParticipantsState(
                    participants: [],
                    layout: .activeSpeaker,
                    activeSpeakerId: nil)
            }
            let currentParticipantIds = Set(participantsState.participants.map(\.id))
            let activePinnedIds = pinnedIds.intersection(currentParticipantIds)

            if activePinnedIds != pinnedIds {
                Task { [weak self] in
                    await self?.pinnedParticipantsDataSource.removeParticipants(notIn: currentParticipantIds)
                }
            }

            let uiParticipants = participantsState.participants.map { participant in
                self.mapToUIParticipant(participant, pinnedIds: activePinnedIds)
            }

            let localUIParticipant = participantsState.localParticipant.map { participant in
                UIParticipant(participant: participant)
            }

            var sortedParticipants: [UIParticipant]
            if layout == .activeSpeaker {
                sortedParticipants = uiParticipants.sortedByDisplayPriority(
                    activeSpeakerId: participantsState.activeParticipantId)
                if let localUIParticipant {
                    if sortedParticipants.isEmpty {
                        sortedParticipants.append(localUIParticipant)
                    } else {
                        sortedParticipants.insert(localUIParticipant, at: 1)
                    }
                }
            } else {
                sortedParticipants = uiParticipants.sortedByCreationDate()
                if let localUIParticipant {
                    if sortedParticipants.isEmpty {
                        sortedParticipants.append(localUIParticipant)
                    } else {
                        sortedParticipants.insert(localUIParticipant, at: 0)
                    }
                }
            }
            return MeetingRoomParticipantsState(
                participants: sortedParticipants,
                layout: layout,
                activeSpeakerId: participantsState.activeParticipantId)
        }

        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                sortedParticipantsPublisher,
                sessionStatePublisher,
                callStatePublisher,
                archivingPublisher
            ),
            noiseSuppressionPublisher
        )
        .map { [weak self] state, noiseSuppressionState in
            let (participantsState, sessionState, callState, archivingState) = state

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
                allowMicrophoneControl: configuration.allowMicrophoneControl,
                allowCameraControl: configuration.allowCameraControl,
                showParticipantList: configuration.showParticipantList,
                callState: callState,
                archivingState: archivingState,
                noiseSuppressionState: noiseSuppressionState
            )
        }
        .removeDuplicates()
        .sink { [weak self] newState in
            Task { @MainActor in
                self?.state = .content(newState)
            }
        }
        .store(in: &cancellables)
    }

    fileprivate func mapToUIParticipant(
        _ participant: Participant,
        pinnedIds: Set<String>
    ) -> UIParticipant {
        var uiParticipant = UIParticipant(
            participant: participant,
            isPinned: pinnedIds.contains(participant.id),
            canBePinned: pinnedIds.isRoomForPinning)
        uiParticipant.onTogglePin = { [weak self] in
            self?.onTogglePin(participantId: participant.id)
        }
        return uiParticipant
    }

    fileprivate func connect() async throws -> CallFacade {
        try await connectToRoomUseCase(roomName: roomName)
    }

    fileprivate func addObservers(_ call: CallFacade) async {
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

        captionsStatusDataSource.captionsState
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateExtraButtons()
                }
            }
            .store(in: &cancellables)

        noiseSuppressionStatusDataSource.noiseSuppressionState
            .sink { [weak self] state in
                self?.handleNoiseSuppressionChange(state)
            }
            .store(in: &cancellables)
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
                self.scheduleDisconnection()
            default:
                break
            }
        }
    }

    /// Schedules a fallback disconnection after a timeout.
    ///
    /// Called when an unexpected session disconnection is detected. The task is stored
    /// so it can be cancelled immediately when the call ends via the normal path
    /// (`navigateBackIfNeeded`), preventing a 6-second strong retain on `self`.
    @MainActor
    fileprivate func scheduleDisconnection() {
        disconnectionTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(MeetingRoomViewModel.disconnectionTimeoutInSeconds))
            } catch {
                return  // Task was cancelled — normal call end already handled cleanup
            }
            try? await self?.disconnectRoomUseCase()
        }
    }

    @MainActor
    fileprivate func updateExtraButtons() {
        updateArchivingButtons()
    }

    @MainActor
    fileprivate func updateArchivingButtons() {
        let archivingState = archivingPublisher.value
        extraButtons = getExternalButtons(.init(archivingState: archivingState))
    }

}

extension Set<String> where Element == String {
    fileprivate var isRoomForPinning: Bool {
        return count < 3
    }
}
