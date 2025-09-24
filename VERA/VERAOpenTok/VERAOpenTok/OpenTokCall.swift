//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import OpenTok
import VERACore

public final class OpenTokCall: CallFacade {
    private var cancellables = Set<AnyCancellable>()
    private let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(ParticipantsState.empty)
    public lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    private var _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(SessionEvent.idle)
    public lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    public var _statePublisher = CurrentValueSubject<VERACore.SessionState, Never>(SessionState.default)
    public lazy var statePublisher: AnyPublisher<VERACore.SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    public let token: String
    public let session: OpenTokSession
    public let publisher: OpenTokPublisher
    public var publisherParticipant: Participant?

    private let callStateManager = CallStateManager()

    enum Error: Swift.Error {
        case subscriberCreationFailed
    }

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
        session.onNewStream = addSubscriber
        session.onStreamDestroyed = removeSubscriber
        session.onSessionFailure = sessionDidFail
        session.onSessionDidConnect = publishToSession

        updateMediaState()
    }

    func updateParticipantsState(_ state: ParticipantsState) async {
        print("updateParticipantsState 1 \(Date())")
        _participantsPublisher.value = .init(
            localParticipant: publisherParticipant,
            participants: state.participants,
            activeParticipantId: state.activeParticipantId
        )
        print("updateParticipantsState 2 \(Date())")
    }

    // MARK: Publisher
    private func publishToSession() {
        do {
            try session.publish(publisher: publisher)
            publisherParticipant = publisher.participant
            publisher.setup()
            setupPublisherObservation(publisher)
        } catch {
            print("Error: \(error.localizedDescription)")
            _eventsPublisher.send(.error(error))
        }
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
        print("OpenTokCall addSubscriber \(stream.streamId)")
        do {
            guard let subscriber = OTSubscriber(stream: stream, delegate: nil) else {
                throw Error.subscriberCreationFailed
            }
            let openTokSubscriber = OpenTokSubscriber(subscriber: subscriber)
            openTokSubscriber.setup()
            openTokSubscriber.onError = { [weak self] in
                self?.removeSubscriber(stream)
            }
            subscriber.delegate = openTokSubscriber
            subscriber.audioLevelDelegate = openTokSubscriber
            subscriber.captionsDelegate = openTokSubscriber

            setupSubscriberObservation(openTokSubscriber)
            setupAudioLevelObservation(openTokSubscriber)

            try session.subscribe(subscriber: openTokSubscriber)

            Task { [weak self] in
                guard let self else { return }
                let state = await callStateManager.addSubscriber(openTokSubscriber)
                print("OpenTokCall addSubscriber \(stream.streamId) DONE")
                await updateParticipantsState(state)
            }
        } catch {
            print("OpenTokCall error \(error)")
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
            .sink { [weak self] audioLevel in
                Task {
                    guard let self = self else { return }
                    let speakerInfo = SpeakerInfo(
                        id: subscriber.participant.id,
                        audioLevel: audioLevel,
                        isMicEnabled: subscriber.participant.isMicEnabled
                    )
                    print("setupAudioLevelObservation 1")
                    let state = await self.callStateManager.updateActiveSpeaker(speakerInfo)
                    print("setupAudioLevelObservation 2")
                    await self.updateParticipantsState(state)
                }
            }
            .store(in: &cancellables)
    }

    private func removeSubscriber(_ stream: OTStream) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let (subscriber, state) = await callStateManager.removeSubscriber(id: stream.streamId)

                if let subscriber = subscriber {
                    try session.unsubscribe(subscriber: subscriber)
                }

                await self.updateParticipantsState(state)
            } catch {
                print("Error: \(error.localizedDescription)")
                _eventsPublisher.send(.error(error))
            }
        }
    }

    // MARK: Session

    public func connect() {
        do {
            try session.connect(with: token)
        } catch {
            print("Error: \(error.localizedDescription)")
            _eventsPublisher.value = .error(error)
        }
    }

    public func disconnect() {
        do {
            try session.disconnect()
            session.onNewStream = nil
            session.onStreamDestroyed = nil
            session.onSessionFailure = nil
            session.onSessionDidConnect = nil
        } catch {
            print("Error: \(error.localizedDescription)")
            _eventsPublisher.value = .error(error)
        }
    }

    private func sessionDidFail(_ error: Swift.Error) {
        _eventsPublisher.send(.error(error))
    }

    // MARK: Audio/Video toggles

    public func toggleLocalCamera() {
        publisher.cameraPosition = publisher.cameraPosition == .front ? .back : .front
    }

    public func toggleLocalVideo() async {
        publisher.publishVideo.toggle()

        updateMediaState()
    }

    public func toggleLocalAudio() async {
        publisher.publishAudio.toggle()

        updateMediaState()
    }

    private func updateMediaState() {
        _statePublisher.value = SessionState(
            isPublishingAudio: publisher.publishAudio,
            isPublishingVideo: publisher.publishVideo)
    }
}
