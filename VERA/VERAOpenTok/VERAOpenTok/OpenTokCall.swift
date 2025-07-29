//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import OpenTok
import VERACore

public final class OpenTokCall: CallFacade {
    private let _participantsPublisher = CurrentValueSubject<[Participant], Never>([])
    public lazy var participantsPublisher: AnyPublisher<[Participant], Never> =
        _participantsPublisher.eraseToAnyPublisher()

    private var _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(SessionEvent.idle)
    public lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    public var _statePublisher = CurrentValueSubject<VERACore.SessionState, Never>(SessionState.default)
    public lazy var statePublisher: AnyPublisher<VERACore.SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    private var subscriberStreams: [String: OpenTokSuscriber] = [:]
    private var participantStreams: [String: Participant] = [:]

    public let token: String
    public let session: OpenTokSession
    public let publisher: OpenTokPublisher

    enum Error: Swift.Error {
        case failedToCreateSuscriber
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

    private func publishToSession() {
        do {
            try session.publish(publisher: publisher)
            participantStreams[publisher.id] = publisher.participant
            updateParticipants()
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func addSubscriber(_ stream: OTStream) {
        do {
            guard let suscriber = OTSubscriber(stream: stream, delegate: nil) else {
                throw Error.failedToCreateSuscriber
            }
            let openTokSuscriber = OpenTokSuscriber(suscriber: suscriber)
            suscriber.delegate = openTokSuscriber
            suscriber.audioLevelDelegate = openTokSuscriber
            suscriber.captionsDelegate = openTokSuscriber

            try session.subscribe(subscriber: openTokSuscriber)

            subscriberStreams[openTokSuscriber.id] = openTokSuscriber
            participantStreams[openTokSuscriber.id] = openTokSuscriber.participant

            updateParticipants()
        } catch {
            _eventsPublisher.send(.error(error))
        }
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

    private func sessionDidFail(_ error: Swift.Error) {
        _eventsPublisher.send(.error(error))
    }

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

    private func updateParticipants() {
        _participantsPublisher.value = Array(participantStreams.values)
    }

    // MARK: Audio/Video toggles

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
}
