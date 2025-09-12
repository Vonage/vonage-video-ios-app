//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import OpenTok
import VERACore

final actor SubscribersRepository {
    private var subscriberStreams: [String: OpenTokSubscriber] = [:]

    func addSubscriber(_ subscriber: OpenTokSubscriber) async {
        subscriberStreams[subscriber.id] = subscriber
    }

    func getSubscriber(id: String) async -> OpenTokSubscriber? {
        subscriberStreams[id]
    }

    func removeSubscriber(id: String) async {
        subscriberStreams.removeValue(forKey: id)
    }
}

final actor ParticipantsRepository {
    private var participantStreams: [String: Participant] = [:]

    var all: [Participant] {
        Array(participantStreams.values)
    }

    func addParticipant(_ participant: Participant) async {
        participantStreams[participant.id] = participant
    }

    func getParticipant(id: String) async -> Participant? {
        participantStreams[id]
    }

    func removeParticipant(id: String) async {
        participantStreams.removeValue(forKey: id)
    }
}

public final class OpenTokCall: CallFacade {
    private var cancellables = Set<AnyCancellable>()
    private let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(ParticipantsState.empty)
    public lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    private var _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(SessionEvent.idle)
    public lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    public var _statePublisher = CurrentValueSubject<VERACore.SessionState, Never>(SessionState.default)
    public lazy var statePublisher: AnyPublisher<VERACore.SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    private let subscribersRepository = SubscribersRepository()
    private let participantsRepository = ParticipantsRepository()

    public let token: String
    public let session: OpenTokSession
    public let publisher: OpenTokPublisher
    public var publisherParticipant: Participant?

    private let activeSpeakerTracker = ActiveSpeakerTracker()

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

    // MARK: Publisher
    private func publishToSession() {
        do {
            try session.publish(publisher: publisher)
            publisherParticipant = publisher.participant
            publisher.setup()
            setupPublisherObservation(publisher)
            Task {
                await updateParticipants()
            }
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func setupPublisherObservation(_ publisher: OpenTokPublisher) {
        publisher.$participant
            .sink { [weak self] participant in
                Task {
                    self?.publisherParticipant = participant
                    await self?.updateParticipants()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Subscriber
    private func addSubscriber(_ stream: OTStream) {
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
            openTokSubscriber.$audioLevel.sink { [weak self] audioLevel in
                self?.activeSpeakerTracker.updatedParticipant(
                    .init(
                        id: openTokSubscriber.participant.id,
                        audioLevel: audioLevel,
                        isMicEnabled:
                            openTokSubscriber.participant.isMicEnabled))
            }.store(in: &cancellables)
            try session.subscribe(subscriber: openTokSubscriber)

            Task {
                await subscribersRepository.addSubscriber(openTokSubscriber)
                await participantsRepository.addParticipant(openTokSubscriber.participant)


                setupSubscriberObservation(openTokSubscriber)

                await recalculateActiveSpeaker()
                await updateParticipants()
            }
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func recalculateActiveSpeaker() async {
        let participants = await participantsRepository.all
        activeSpeakerTracker.calculateActiveSpeaker(
            from: participants.map {
                SpeakerInfo(id: $0.id, audioLevel: 0, isMicEnabled: $0.isMicEnabled)
            })
    }

    private func setupSubscriberObservation(_ subscriber: OpenTokSubscriber) {
        subscriber.$participant
            .sink { [weak self] participant in
                Task {
                    await self?.participantsRepository.addParticipant(participant)
                    await self?.updateParticipants()
                }
            }
            .store(in: &cancellables)
    }

    private func removeSubscriber(_ stream: OTStream) {
        Task {
            guard let subscriber = await subscribersRepository.getSubscriber(id: stream.streamId) else { return }

            do {
                await subscribersRepository.removeSubscriber(id: stream.streamId)
                await participantsRepository.removeParticipant(id: stream.streamId)
                await recalculateActiveSpeaker()
                await updateParticipants()

                try session.unsubscribe(subscriber: subscriber)
            } catch {
                _eventsPublisher.send(.error(error))
            }
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

    public func disconnect() {
        do {
            try session.disconnect()
        } catch {
            _eventsPublisher.value = .error(error)
        }
    }

    private func sessionDidFail(_ error: Swift.Error) {
        _eventsPublisher.send(.error(error))
    }

    private func updateParticipants() async {
        print("updateParticipants")

        let participants = await participantsRepository.all
        _participantsPublisher.value = .init(
            localParticipant: publisherParticipant,
            participants: participants,
            activeParticipantId: activeSpeakerTracker.activeSpeaker.participantId)
    }

    // MARK: Audio/Video toggles

    public func toggleLocalCamera() {
        publisher.cameraPosition = publisher.cameraPosition == .front ? .back : .front
    }

    public func toggleLocalVideo() {
        Task {
            publisher.publishVideo.toggle()

            updateMediaState()
            await updateParticipants()
        }
    }

    public func toggleLocalAudio() {
        Task {
            publisher.publishAudio.toggle()

            updateMediaState()
            await updateParticipants()
        }
    }

    private func updateMediaState() {
        _statePublisher.value = SessionState(
            isPublishingAudio: publisher.publishAudio,
            isPublishingVideo: publisher.publishVideo)
    }
}
