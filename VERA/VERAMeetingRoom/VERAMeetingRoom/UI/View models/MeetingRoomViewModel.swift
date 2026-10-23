//
//  Created by Vonage on 23/7/25.
//

import Combine
import Foundation
import Observation
import VERACommonUI
import VERADomain

public enum MeetingRoomViewState: Equatable, Sendable {
    case loading
    case content(MeetingRoomState)
}

public struct MeetingRoomOverlayState {
    public let captions: [CaptionItem]

    public init(captions: [CaptionItem]) {
        self.captions = captions
    }
}

public struct ForceMuteConfirmation: Identifiable, Equatable {
    public let participantId: String
    public let participantName: String

    public init(participantId: String, participantName: String) {
        self.participantId = participantId
        self.participantName = participantName
    }

    public var id: String { participantId }

    public var message: String {
        let messageFormat = String(
            localized: "Mute %@ for everyone in the call? Only %@ can unmute themselves.",
            bundle: .module
        )
        return String(format: messageFormat, participantName, participantName)
    }

    public static var cancelButtonTitle: String {
        String(localized: "Cancel", bundle: .module)
    }

    public static var muteButtonTitle: String {
        String(localized: "Mute", bundle: .module)
    }
}

@Observable
@MainActor
public final class MeetingRoomViewModel {

    // Kept per instance so bounded fallback behavior can be exercised without a global test clock.
    @ObservationIgnored var disconnectionTimeout: Duration = .seconds(6)
    @ObservationIgnored var disconnectionDelay: @MainActor (Duration) async throws -> Void = {
        try await Task.sleep(for: $0)
    }

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private let connectToRoomUseCase: ConnectToRoomUseCase
    @ObservationIgnored
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    @ObservationIgnored
    private let disconnectRoomUseCase: DisconnectRoomUseCase
    @ObservationIgnored
    private let checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase
    @ObservationIgnored
    private let checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase
    @ObservationIgnored
    private let configuration: MeetingRoomConfiguration
    @ObservationIgnored
    private let meetingRoomNavigation: MeetingRoomDestination
    @ObservationIgnored
    private let captionsStatusDataSource: CaptionsStatusDataSource
    @ObservationIgnored
    private let noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource
    @ObservationIgnored
    private let pinnedParticipantsDataSource: PinnedParticipantsDataSource
    @ObservationIgnored
    private let uiProvider: any MeetingRoomUIProvider
    @ObservationIgnored
    private var speakingWhileMutedDetector: SpeakingWhileMutedDetector?

    @MainActor public var state: MeetingRoomViewState = .loading
    @MainActor public var toast: ToastItem?
    @MainActor public var extraButtons: [BottomBarButton] = []
    @MainActor public var extraTopTrailingButtons: [ViewGenerator] = []
    @MainActor public var isArchiving = false

    /// Tracks the fallback disconnection task so it can be cancelled on normal call end.
    @MainActor @ObservationIgnored private(set) var disconnectionTask: Task<Void, Never>?

    @MainActor @ObservationIgnored private var isSessionInterrupted = false

    @ObservationIgnored
    private let layoutPublisher = CurrentValueSubject<MeetingRoomLayout, Never>(.activeSpeaker)
    @ObservationIgnored
    private let sessionStatePublisher = CurrentValueSubject<SessionState, Never>(.initial)
    @ObservationIgnored
    private let callStatePublisher = CurrentValueSubject<CallState, Never>(.idle)
    @ObservationIgnored
    private let archivingPublisher = CurrentValueSubject<ArchivingState, Never>(.idle)
    @ObservationIgnored
    private let transcriptionPublisher = CurrentValueSubject<ArchivingState, Never>(.idle)
    @ObservationIgnored
    private let noiseSuppressionPublisher = CurrentValueSubject<NoiseSuppressionState, Never>(.idle)

    @ObservationIgnored
    public weak var currentCall: CallFacade?

    public let roomName: RoomName
    public let baseURL: URL
    @ObservationIgnored
    private var initialised = false

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
        uiProvider: any MeetingRoomUIProvider,
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
        self.uiProvider = uiProvider
        self.captionsStatusDataSource = captionsStatusDataSource
        self.noiseSuppressionStatusDataSource = noiseSuppressionStatusDataSource
        self.pinnedParticipantsDataSource = pinnedParticipantsDataSource
    }

    @MainActor
    public func loadUI() async {
        guard !initialised else { return }
        initialised = true

        uiProvider.updates
            .sinkOnMainActor { [weak self] in
                self?.updateExtraButtons()
            }
            .store(in: &cancellables)

        do {
            await MediaPermissions.requestPermissionsIfNeeded()

            let call = try await connect()
            currentCall = call

            await addObservers(call)

            updateExtraButtons()
        } catch is UnauthorizedError {
            await MainActor.run { [weak self] in
                self?.meetingRoomNavigation.onBack()
            }
        } catch is AuthenticationError {
            await MainActor.run { [weak self] in
                self?.meetingRoomNavigation.onBack()
            }
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

    public func onForceMute(participantId: String, participantName: String) {
        guard currentCall != nil else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let confirmation = ForceMuteConfirmation(
                participantId: participantId,
                participantName: participantName
            )
            meetingRoomNavigation.presentForceMuteConfirmation(
                message: confirmation.message,
                confirmTitle: ForceMuteConfirmation.muteButtonTitle,
                cancelTitle: ForceMuteConfirmation.cancelButtonTitle
            ) { [weak self] in
                self?.forceMute(
                    participantId: confirmation.participantId,
                    participantName: confirmation.participantName
                )
            }
        }
    }

    private func forceMute(participantId: String, participantName: String) {
        Task { @MainActor [weak self] in
            guard let self, let currentCall = self.currentCall else { return }
            do {
                try await currentCall.forceMuteParticipant(id: participantId)
                let messageFormat = String(localized: "%@ was muted.", bundle: .module)
                self.toast = .init(
                    message: String(format: messageFormat, participantName),
                    mode: .success
                )
            } catch {
                self.toast = .init(message: error.localizedDescription, mode: .failure)
            }
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
        noiseSuppressionPublisher.value = noiseSuppressionState
    }

    fileprivate func navigateBackIfNeeded(_ callState: CallState) {
        if callState == .disconnecting || callState == .disconnected {
            disconnectionTask?.cancel()
            disconnectionTask = nil
        }
        guard callState == .disconnected else { return }
        meetingRoomNavigation.onNext()
    }

    fileprivate func observeSessionState(_ participantsPublisher: AnyPublisher<ParticipantsState, Never>) {
        let sortedParticipantsPublisher = Publishers.CombineLatest3(
            // Each upstream enters the UI scheduler before the UI-state mapping below.
            participantsPublisher.removeDuplicates().receive(on: DispatchQueue.main),
            layoutPublisher,
            pinnedParticipantsDataSource.pinnedParticipantIds.receive(on: DispatchQueue.main)
        )
        .map { [weak self] participantsState, layout, pinnedIds -> MeetingRoomParticipantsState in
            MainActor.assumeIsolated {
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
        }

        Publishers.CombineLatest3(
            Publishers.CombineLatest4(
                sortedParticipantsPublisher,
                sessionStatePublisher,
                callStatePublisher,
                archivingPublisher
            ),
            transcriptionPublisher,
            noiseSuppressionPublisher
        )
        .map { [weak self] state, transcriptionState, noiseSuppressionState in
            MainActor.assumeIsolated {
                let (participantsState, sessionState, callState, archivingState) = state

                guard let self else { return MeetingRoomState.initial }
                return MeetingRoomState(
                    roomName: self.roomName,
                    roomURL: self.baseURL.meetingRoomURL(self.roomName),
                    isMicEnabled: sessionState.isPublishingAudio
                        && self.checkMicrophoneAuthorizationStatusUseCase().isAuthorized,
                    isCameraEnabled: sessionState.isPublishingVideo
                        && self.checkCameraAuthorizationStatusUseCase().isAuthorized,
                    participants: participantsState.participants,
                    layout: participantsState.layout,
                    activeSpeakerId: participantsState.activeSpeakerId,
                    allowMicrophoneControl: self.configuration.allowMicrophoneControl,
                    allowCameraControl: self.configuration.allowCameraControl,
                    showParticipantList: self.configuration.showParticipantList,
                    callState: callState,
                    archivingState: archivingState,
                    transcriptionState: transcriptionState,
                    noiseSuppressionState: noiseSuppressionState
                )
            }
        }
        .removeDuplicates()
        .sinkOnMainActor { [weak self] newState in
            self?.state = .content(newState)
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
        if currentCall != nil,
            participant.isRemote,
            !participant.isScreenshare,
            participant.isMicEnabled
        {
            uiParticipant.onForceMute = { [weak self] in
                self?.onForceMute(participantId: participant.id, participantName: participant.name)
            }
        }
        return uiParticipant
    }

    fileprivate func connect() async throws -> CallFacade {
        try await connectToRoomUseCase(roomName: roomName)
    }

    fileprivate func addObservers(_ call: CallFacade) async {
        observeSessionState(call.participantsPublisher)

        call.statePublisher
            .sinkOnMainActor { [weak self] state in
                self?.sessionStatePublisher.send(state)
            }
            .store(in: &cancellables)

        call.callState
            .sinkOnMainActor { [weak self] callState in
                self?.callStatePublisher.send(callState)
                self?.navigateBackIfNeeded(callState)
            }
            .store(in: &cancellables)

        call.archivingState
            .removeDuplicates()
            .dropFirst()
            .sinkOnMainActor { [weak self] archivingState in
                self?.handleArchivingStateChange(archivingState)
            }
            .store(in: &cancellables)

        call.transcriptionState
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] transcriptionState in
                self?.handleTranscriptionStateChange(transcriptionState)
            }
            .store(in: &cancellables)

        call.eventsPublisher
            .sinkOnMainActor { [weak self] event in
                self?.handleEvents(event)
            }
            .store(in: &cancellables)

        captionsStatusDataSource.captionsState
            .sinkOnMainActor { [weak self] _ in
                self?.updateExtraButtons()
            }
            .store(in: &cancellables)

        noiseSuppressionStatusDataSource.noiseSuppressionState
            .sinkOnMainActor { [weak self] state in
                self?.handleNoiseSuppressionChange(state)
            }
            .store(in: &cancellables)

        let detector = SpeakingWhileMutedDetector(
            // Read microphone changes at the same source boundary as audio samples. The
            // UI-forwarded session state may still be queued when the next sample arrives.
            isMicEnabled: call.statePublisher.map(\.isPublishingAudio).eraseToAnyPublisher(),
            audioLevel: call.publisherAudioLevelPublisher
        )
        speakingWhileMutedDetector = detector

        detector.isSpeakingWhileMuted
            .filter { @Sendable in $0 }
            .sinkOnMainActor { [weak self] _ in
                self?.toast = ToastItem(
                    message: String(localized: "You're muted. Tap the mic button to unmute.", bundle: .module),
                    mode: .warning)
            }
            .store(in: &cancellables)
    }

    fileprivate func handleArchivingStateChange(_ archivingState: ArchivingState) {
        self.archivingPublisher.value = archivingState
        switch archivingState {
        case .idle:
            self.toast = .init(
                message: String(localized: "Session recording stopped", bundle: .module),
                mode: .info)
        case .archiving:
            self.toast = .init(
                message: String(localized: "Session recording started", bundle: .module),
                mode: .info)
        }
    }

    fileprivate func handleTranscriptionStateChange(_ transcriptionState: ArchivingState) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.transcriptionPublisher.value = transcriptionState
            switch transcriptionState {
            case .idle:
                // A reset during interruption or teardown is not a transcription-stop notification.
                guard !self.isSessionInterrupted,
                    self.callStatePublisher.value != .disconnecting,
                    self.callStatePublisher.value != .disconnected
                else { return }
                self.toast = .init(
                    message: String(localized: "Session transcription stopped", bundle: .module),
                    mode: .info)
            case .archiving:
                self.toast = .init(
                    message: String(localized: "Session transcription started", bundle: .module),
                    mode: .info)
            }
        }
    }

    fileprivate func handleEvents(_ event: SessionEvent) {
        switch event {
        case .didBeginReconnecting:
            self.isSessionInterrupted = true
            self.toast = .init(
                message: String(localized: "Session did drop, started reconnection", bundle: .module),
                mode: .warning)
        case .didReconnect:
            self.isSessionInterrupted = false
            self.toast = .init(
                message: String(localized: "Session did reconnect", bundle: .module),
                mode: .info)
        case .muteForced:
            self.toast = .init(
                message: String(localized: "You were muted by the host.", bundle: .module),
                mode: .warning)
        case .error(let error):
            self.toast = .init(message: error.localizedDescription, mode: .failure)
        case .sessionFailure(let error):
            self.toast = .init(message: error.localizedDescription, mode: .failure)
        case .disconnected:
            self.isSessionInterrupted = true
            self.toast = .init(
                message: String(localized: "Session did disconnect", bundle: .module),
                mode: .failure)
            self.scheduleDisconnection()
        default:
            break
        }
    }

    /// Schedules a fallback disconnection after a timeout.
    ///
    /// Called when an unexpected session disconnection is detected. The task is stored
    /// so it can be cancelled immediately when the call ends via the normal path
    /// (`navigateBackIfNeeded`), preventing a 6-second strong retain on `self`.
    @MainActor
    fileprivate func scheduleDisconnection() {
        guard !isTearingDown else { return }
        disconnectionTask?.cancel()
        let timeout = disconnectionTimeout
        let delay = disconnectionDelay
        disconnectionTask = Task { [weak self] in
            do {
                try await delay(timeout)
            } catch {
                return  // Task was cancelled — normal call end already handled cleanup
            }
            guard let self, !Task.isCancelled, !self.isTearingDown else { return }
            self.disconnectionTask = nil
            try? await self.disconnectRoomUseCase()
        }
    }

    private var isTearingDown: Bool {
        callStatePublisher.value == .disconnecting || callStatePublisher.value == .disconnected
    }

    @MainActor
    fileprivate func updateExtraButtons() {
        extraButtons = uiProvider.bottomBarButtons()
    }

}

extension Set<String> where Element == String {
    fileprivate var isRoomForPinning: Bool {
        return count < 3
    }
}
