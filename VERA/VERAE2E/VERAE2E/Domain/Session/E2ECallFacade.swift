//
//  Created by Vonage on 8/6/26.
//

import Combine
import Foundation
import VERADomain
import VERAVonage

public final class E2ECallFacade: CallFacade, AudioMuteControllable {
    public lazy var _publisherAudioLevelPublisher = CurrentValueSubject<Float, Never>(0.0)
    public lazy var publisherAudioLevelPublisher = _publisherAudioLevelPublisher.eraseToAnyPublisher()

    private var cancellables = Set<AnyCancellable>()
    private let scenario: any E2ETestScenario
    private let pluginNotifier: E2ECallPluginNotifier

    private let networkStatsSubject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)
    public lazy var networkStatsPublisher = networkStatsSubject.eraseToAnyPublisher()

    private let eventsSubject = CurrentValueSubject<SessionEvent, Never>(.idle)
    public lazy var eventsPublisher = eventsSubject.eraseToAnyPublisher()

    private let participantsSubject: CurrentValueSubject<ParticipantsState, Never>
    public lazy var participantsPublisher = participantsSubject.eraseToAnyPublisher()

    private let stateSubject: CurrentValueSubject<SessionState, Never>
    private var mediaBeforeHold: SessionState?
    private var wantsSpeakingWhileMutedSimulation = false
    public lazy var statePublisher = stateSubject.eraseToAnyPublisher()

    private let callStateSubject = CurrentValueSubject<CallState, Never>(.idle)
    public lazy var callState = callStateSubject.eraseToAnyPublisher()

    private let archivingStateSubject = CurrentValueSubject<ArchivingState, Never>(.idle)
    public lazy var archivingState = archivingStateSubject.eraseToAnyPublisher()

    private let captionsSubject = CurrentValueSubject<[CaptionItem], Never>([])
    public lazy var captionsPublisher = captionsSubject.eraseToAnyPublisher()

    public private(set) var isMuted = false
    public private(set) var isOnHold = false
    public private(set) var areCaptionsEnabled = false

    public init(
        publisherSettings: PublisherSettings = .init(),
        plugins: [any VonagePlugin] = [],
        credentials: RoomCredentials? = nil,
        scenario: any E2ETestScenario = E2EConfiguration.scenario
    ) {
        self.scenario = scenario
        pluginNotifier = E2ECallPluginNotifier(
            plugins: plugins,
            callParams: E2ECallParamsBuilder.callParams(from: credentials))
        stateSubject = CurrentValueSubject<SessionState, Never>(
            .init(
                isPublishingAudio: publisherSettings.publishAudio,
                isPublishingVideo: publisherSettings.publishVideo))
        participantsSubject = CurrentValueSubject<ParticipantsState, Never>(
            scenario.fixture.participantsState
        )
        pluginNotifier.assign(call: self)
        observeArchivingEvents()
    }

    public func connect() async throws {
        callStateSubject.send(.connecting)
        callStateSubject.send(.connected)
        eventsSubject.send(.connected)
        Task { await pluginNotifier.notifyCallDidStart() }
    }

    public func disconnect() async throws {
        callStateSubject.send(.disconnecting)
        await pluginNotifier.notifyCallDidEnd()
        callStateSubject.send(.disconnected)
        eventsSubject.send(.disconnected)
        pluginNotifier.unassign()
    }

    public func toggleLocalVideo() {
        let current = mediaBeforeHold ?? stateSubject.value
        updateDesiredMedia(
            .init(
                isPublishingAudio: current.isPublishingAudio,
                isPublishingVideo: !current.isPublishingVideo))
    }

    public func toggleLocalCamera() {}

    public func toggleLocalAudio() {
        let current = mediaBeforeHold ?? stateSubject.value
        let newIsPublishingAudio = !current.isPublishingAudio
        updateDesiredMedia(
            .init(
                isPublishingAudio: newIsPublishingAudio,
                isPublishingVideo: current.isPublishingVideo))

        wantsSpeakingWhileMutedSimulation = !newIsPublishingAudio
        if wantsSpeakingWhileMutedSimulation && !isOnHold {
            simulateSpeakingWhileMuted()
        } else {
            stopSpeakingWhileMutedSimulation()
        }
    }

    public func muteLocalMedia(_ isMuted: Bool) {
        updateDesiredMedia(.init(isPublishingAudio: !isMuted, isPublishingVideo: !isMuted))
        stopSpeakingWhileMutedSimulationIfUnmuted(isMuted)
    }

    public func muteLocalAudio(_ isMuted: Bool) {
        let current = mediaBeforeHold ?? stateSubject.value
        updateDesiredMedia(.init(isPublishingAudio: !isMuted, isPublishingVideo: current.isPublishingVideo))
        stopSpeakingWhileMutedSimulationIfUnmuted(isMuted)
    }

    public func setOnHold(_ isOnHold: Bool) {
        guard self.isOnHold != isOnHold else { return }
        self.isOnHold = isOnHold
        if isOnHold {
            mediaBeforeHold = stateSubject.value
            stopSpeakingWhileMutedSimulation()
            publishMedia(.init(isPublishingAudio: false, isPublishingVideo: false))
        } else if let savedMedia = mediaBeforeHold {
            mediaBeforeHold = nil
            publishMedia(savedMedia)
            if wantsSpeakingWhileMutedSimulation && !savedMedia.isPublishingAudio {
                simulateSpeakingWhileMuted()
            }
        }
    }

    private func updateDesiredMedia(_ state: SessionState) {
        if isOnHold {
            mediaBeforeHold = state
        } else {
            publishMedia(state)
        }
    }

    private func publishMedia(_ state: SessionState) {
        isMuted = !state.isPublishingAudio && !state.isPublishingVideo
        stateSubject.send(state)
    }

    public func enableCaptions() async {
        areCaptionsEnabled = true
        captionsSubject.send(
            hasDeterministicCaptions ? E2ECallCaptionsFactory.enabledCaptions() : [])
    }

    public func disableCaptions() async {
        areCaptionsEnabled = false
        captionsSubject.send([])
    }

    public func enableNetworkStats() {}

    public func disableNetworkStats() {
        networkStatsSubject.send(.empty)
    }

    public func enableSubscriberExtraStats() {}

    public func disableSubscriberExtraStats() {}

    public func applyPublisherAdvancedSettings(_ settings: PublisherAdvancedSettings) async throws {}

    public func updateLivePublisherAdvancedSettings(_ settings: VERADomain.PublisherAdvancedSettings) async {}

    private var hasDeterministicCaptions: Bool {
        guard let captionsFixture = scenario.fixture as? any E2ECaptionsScenarioFixture else {
            return false
        }

        return captionsFixture.mode == .deterministic
    }

    private func observeArchivingEvents() {
        NotificationCenter.default.publisher(for: E2EArchivingEvents.didStart)
            .sink { [weak self] notification in
                guard let archiveId = notification.object as? String else { return }
                self?.archivingStateSubject.send(.archiving(archiveId))
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: E2EArchivingEvents.didStop)
            .sink { [weak self] _ in
                self?.archivingStateSubject.send(.idle)
            }
            .store(in: &cancellables)
    }

    public func forceMuteParticipant(id: String) async throws {
        let currentState = participantsSubject.value
        guard let participant = currentState.participants.first(where: { $0.id == id }) else {
            throw ParticipantForceMuteError.participantNotFound
        }

        let mutedParticipant = Participant(
            id: participant.id,
            connectionId: participant.connectionId,
            name: participant.name,
            isMicEnabled: false,
            isCameraEnabled: participant.isCameraEnabled,
            videoDimensions: participant.videoDimensions,
            isRemote: participant.isRemote,
            creationTime: participant.creationTime,
            isScreenshare: participant.isScreenshare,
            audioLevel: participant.audioLevel,
            view: participant.view
        )
        let participants = currentState.participants.map {
            $0.id == id ? mutedParticipant : $0
        }
        participantsSubject.send(
            ParticipantsState(
                localParticipant: currentState.localParticipant,
                participants: participants,
                activeParticipantId: currentState.activeParticipantId
            )
        )
    }

    // MARK: - Speaking While Muted Simulation

    private var speakingWhileMutedTimer: Timer?

    /// Simulates sustained loud audio levels while the mic is muted.
    /// This triggers the `SpeakingWhileMutedDetector` in E2E mode so the
    /// warning toast can be validated by Maestro flows.
    private func simulateSpeakingWhileMuted() {
        stopSpeakingWhileMutedSimulation()
        // Emit loud audio samples every 0.3s to trigger the detector's hysteresis
        speakingWhileMutedTimer = Timer.scheduledTimer(
            withTimeInterval: 0.3,
            repeats: true
        ) { [weak self] _ in
            self?._publisherAudioLevelPublisher.send(0.5)
        }
    }

    private func stopSpeakingWhileMutedSimulation() {
        speakingWhileMutedTimer?.invalidate()
        speakingWhileMutedTimer = nil
        _publisherAudioLevelPublisher.send(0.0)
    }

    /// System unmutes must end a simulation started by `toggleLocalAudio()`,
    /// otherwise loud samples keep flowing while audio is published.
    private func stopSpeakingWhileMutedSimulationIfUnmuted(_ isMuted: Bool) {
        guard !isMuted, wantsSpeakingWhileMutedSimulation else { return }
        wantsSpeakingWhileMutedSimulation = false
        stopSpeakingWhileMutedSimulation()
    }
}
