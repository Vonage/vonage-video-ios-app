//
//  Created by Vonage on 29/7/25.
//

import Combine
import Foundation
import VERACore

public class MockCall: VERACore.CallFacade {
    public let _eventsPublisher = CurrentValueSubject<VERACore.SessionEvent, Never>(.idle)
    public lazy var eventsPublisher: AnyPublisher<VERACore.SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    public let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(ParticipantsState.empty)
    public lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    public let _statePublisher = CurrentValueSubject<VERACore.SessionState, Never>(SessionState.initial)
    public lazy var statePublisher: AnyPublisher<VERACore.SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    public var recordedActions: [CallActions] = []

    public enum CallActions: String {
        case connect
        case disconnect
        case toggleLocalVideo
        case toggleLocalAudio
        case toggleLocalCamera
    }

    public init() {}

    public func connect() {
        recordedActions.append(.connect)
    }

    public func disconnect() {
        recordedActions.append(.disconnect)
    }

    public func toggleLocalVideo() {
        recordedActions.append(.toggleLocalVideo)
    }

    public func toggleLocalAudio() {
        recordedActions.append(.toggleLocalAudio)
    }

    public func toggleLocalCamera() {
        recordedActions.append(.toggleLocalCamera)
    }
}
