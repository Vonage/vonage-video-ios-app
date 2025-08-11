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

    private var subscriberStreams: [String: OpenTokSubscriber] = [:]
    private var participantStreams: [String: Participant] = [:]

    public let token: String
    public let session: OpenTokSession
    public let publisher: OpenTokPublisher
    public var publisherParticipant: Participant?

    enum Error: Swift.Error {
        case failedToCreateSubscriber
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
            updateParticipants()
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func setupPublisherObservation(_ publisher: OpenTokPublisher) {
        publisher.$participant
            .sink { [weak self] participant in
                self?.publisherParticipant = participant
                self?.updateParticipants()
            }
            .store(in: &cancellables)
    }

    // MARK: Subscriber
    private func addSubscriber(_ stream: OTStream) {
        do {
            guard let subscriber = OTSubscriber(stream: stream, delegate: nil) else {
                throw Error.failedToCreateSubscriber
            }
            let openTokSubscriber = OpenTokSubscriber(subscriber: subscriber)
            openTokSubscriber.setup()
            subscriber.delegate = openTokSubscriber
            subscriber.audioLevelDelegate = openTokSubscriber
            subscriber.captionsDelegate = openTokSubscriber

            try session.subscribe(subscriber: openTokSubscriber)

            subscriberStreams[openTokSubscriber.id] = openTokSubscriber
            participantStreams[openTokSubscriber.id] = openTokSubscriber.participant

            setupSubscriberObservation(openTokSubscriber)
            updateParticipants()
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func setupSubscriberObservation(_ subscriber: OpenTokSubscriber) {
        subscriber.$participant
            .sink { [weak self] participant in
                self?.participantStreams[participant.id] = participant
                self?.updateParticipants()
            }
            .store(in: &cancellables)
    }

    private func removeSubscriber(_ stream: OTStream) {
        guard let subscriber = subscriberStreams[stream.streamId] else { return }

        do {
            subscriberStreams.removeValue(forKey: stream.streamId)
            participantStreams.removeValue(forKey: stream.streamId)

            updateParticipants()

            try session.unsubscribe(subscriber: subscriber)
        } catch {
            _eventsPublisher.send(.error(error))
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

    private func updateParticipants() {
        _participantsPublisher.value = .init(
            localParticipant: publisherParticipant,
            participants: Array(participantStreams.values))
    }

    // MARK: Audio/Video toggles

    public func toggleLocalCamera() {
        publisher.cameraPosition = publisher.cameraPosition == .front ? .back : .front
    }

    public func toggleLocalVideo() {
        publisher.publishVideo.toggle()

        updateMediaState()
        updateParticipants()
    }

    public func toggleLocalAudio() {
        publisher.publishAudio.toggle()

        updateMediaState()
        updateParticipants()
    }

    private func updateMediaState() {
        _statePublisher.value = SessionState(
            isPublishingAudio: publisher.publishAudio,
            isPublishingVideo: publisher.publishVideo)
    }
}
