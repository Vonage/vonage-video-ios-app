//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import OpenTok
import VERACore

public final class OpenTokCall: CallFacade {

    enum Error: Swift.Error {
        case SelfMissingOnDisconnect
    }

    private var cancellables = Set<AnyCancellable>()
    private let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(ParticipantsState.empty)
    public lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    private var _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(SessionEvent.idle)
    public lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    public var _statePublisher = CurrentValueSubject<VERACore.SessionState, Never>(SessionState.default)
    public lazy var statePublisher: AnyPublisher<VERACore.SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    public let id: UUID = UUID()
    public let token: String
    public let session: OpenTokSession
    public let publisher: OpenTokPublisher
    public var publisherParticipant: Participant?
    private let subscriberFactory = OpenTokSubscriberFactory()

    private let activeSpeakerTracker = ActiveSpeakerTracker()
    private lazy var callStateManager = CallStateManager(
        activeSpeakerTracker: activeSpeakerTracker)

    public var plugins: [OpenTokPlugin] = []
    
    public init(
        token: String,
        session: OpenTokSession,
        publisher: OpenTokPublisher
    ) {
        self.token = token
        self.session = session
        self.publisher = publisher
    }

    public func setup() {
        setupSessionHandlers()
        updateMediaState()
        setupActiveSpeakerObservation()
    }

    func setupSessionHandlers() {
        session.onNewStream = { [weak self] stream in
            self?.addSubscriber(stream)
        }
        session.onStreamDestroyed = { [weak self] stream in
            self?.removeSubscriber(stream)
        }
        session.onSessionFailure = { [weak self] error in
            self?.sessionDidFail(error)
        }
        session.onSessionDidConnect = { [weak self] in
            self?.publishToSession()
        }
        session.onSessionSignal = { [weak self] signal in
            self?.handleSignal(signal)
        }
    }
    
    func updateParticipantsState(_ state: ParticipantsState) async {
        _participantsPublisher.value = .init(
            localParticipant: publisherParticipant,
            participants: state.participants,
            activeParticipantId: state.activeParticipantId
        )
    }

    // MARK: Publisher
    
    private func publishToSession() {
        guard !publisher.hasSession else { return }
        do {
            try session.publish(publisher: publisher)
            publisherParticipant = publisher.participant
            publisher.setup()
            setupPublisherObservation(publisher)
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func setupActiveSpeakerObservation() {
        activeSpeakerTracker.$activeSpeaker
            .removeDuplicates()
            .sink { info in
                Task { [weak self] in
                    guard let self else { return }
                    let state = await self.callStateManager.getCurrentState()
                    await self.updateParticipantsState(state)
                }
            }
            .store(in: &cancellables)
    }

    private func setupPublisherObservation(_ publisher: OpenTokPublisher) {
        publisher.$participant
            .sink { [weak self] participant in
                guard let self = self else { return }
                self.publisherParticipant = participant

                let currentState = self._participantsPublisher.value

                let newState = ParticipantsState(
                    localParticipant: participant,
                    participants: currentState.participants,
                    activeParticipantId: currentState.activeParticipantId
                )
                Task { [weak self] in
                    await self?.updateParticipantsState(newState)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Subscriber

    private func addSubscriber(_ stream: OTStream) {
        Task { [weak self] in
            guard let self else { return }
            await self.doSubscribe(stream)
        }
    }

    @MainActor
    private func doSubscribe(_ stream: OTStream) async {
        do {
            let openTokSubscriber = try subscriberFactory.makeSubscriber(stream)
            openTokSubscriber.onError = { [weak self] in
                self?.removeSubscriber(stream)
            }

            setupSubscriberObservation(openTokSubscriber)
            setupAudioLevelObservation(openTokSubscriber)

            try session.subscribe(subscriber: openTokSubscriber)

            let state = await callStateManager.addSubscriber(openTokSubscriber)
            await updateParticipantsState(state)
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }


    private func setupSubscriberObservation(_ subscriber: OpenTokSubscriber) {
        subscriber.$participant
            .sink { participant in
                Task { [weak self] in
                    guard let self = self else { return }
                    let state = await self.callStateManager.updateParticipant(participant)
                    await self.updateParticipantsState(state)
                }
            }
            .store(in: &cancellables)
    }

    private func setupAudioLevelObservation(_ subscriber: OpenTokSubscriber) {
        subscriber.$audioLevel
            .sink { audioLevel in
                Task { [weak self] in
                    guard let self = self else { return }
                    let speakerInfo = SpeakerInfo(
                        id: subscriber.participant.id,
                        audioLevel: audioLevel,
                        isMicEnabled: subscriber.participant.isMicEnabled
                    )
                    await self.callStateManager.updateActiveSpeaker(speakerInfo)
                }
            }
            .store(in: &cancellables)
    }

    private func removeSubscriber(_ stream: OTStream) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let (_, state) = await callStateManager.removeSubscriber(id: stream.streamId)
            // There is no need to do a session unsubscribe if the stream has been destroyed
            await self.updateParticipantsState(state)
        }
    }

    // MARK: Session

    public func connect() {
        do {
            try session.connect(with: token)
        } catch {
            _eventsPublisher.value = .error(error)
        }
    }

    var disconnectContinuation: CheckedContinuation<Void, Swift.Error>?

    public func disconnect() async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.disconnectContinuation = continuation
            Task { @MainActor [weak self] in
                guard let self else {
                    self?.disconnectContinuation?.resume(throwing: Error.SelfMissingOnDisconnect)
                    self?.disconnectContinuation = nil
                    return
                }
                do {
                    self.publisher.onStreamDestroyed = { [weak self] in
                        self?.cleanUp()
                    }

                    assertMainThread()

                    // If publisher does not have a session, doesn't need
                    // to be unpublished.
                    if publisher.hasSession {
                        try self.session.unpublish(publisher: publisher)
                    } else {
                        self.cleanUp()
                    }
                } catch {
                    self.disconnectContinuation?.resume(throwing: error)
                    self.disconnectContinuation = nil
                    self.cleanUp()
                    self._eventsPublisher.value = .error(error)
                }
            }
        }
    }

    private func cleanUp() {
        do {
            Task { [weak self] in
                guard let self else { return }
                await self.callStateManager.cleanUpParticipants()
            }

            clearPluginChannels()
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
            try session.disconnect()
            publisher.cleanUp()
            session.cleanUp()
            disconnectContinuation?.resume()
            disconnectContinuation = nil
        } catch {
            _eventsPublisher.value = .error(error)

            disconnectContinuation?.resume(throwing: error)
            disconnectContinuation = nil
        }
    }

    private func sessionDidFail(_ error: Swift.Error) {
        _eventsPublisher.send(.error(error))
    }

    // MARK: Audio/Video toggles

    public func toggleLocalCamera() {
        publisher.cameraPosition = publisher.cameraPosition == .front ? .back : .front
    }

    public func toggleLocalVideo() {
        publisher.publishVideo.toggle()

        updateMediaState()
    }

    public func toggleLocalAudio() {
        publisher.publishAudio.toggle()

        updateMediaState()
    }

    private func updateMediaState() {
        _statePublisher.value = SessionState(
            isPublishingAudio: publisher.publishAudio,
            isPublishingVideo: publisher.publishVideo)
    }
    
    // MARK: Signals
    
    public func registerPlugins(_ plugins: [OpenTokPlugin]) {
        self.plugins = plugins
        
        plugins.forEach { $0.channel = session }
    }
    
    private func clearPluginChannels() {
        plugins.forEach { $0.channel = nil }
        
        plugins.removeAll()
    }
    
    private func handleSignal(_ signal: OpenTokSignal) {
        print(signal.type, signal.data ?? "")
        plugins.forEach { $0.handleSignal(signal) }
    }
}
