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

    public let _statePublisher = CurrentValueSubject<VERACore.SessionState, Never>(SessionState.default)
    public lazy var statePublisher: AnyPublisher<VERACore.SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    public var _callState = CurrentValueSubject<CallState, Never>(CallState.idle)
    public lazy var callState: AnyPublisher<CallState, Never> = _callState.eraseToAnyPublisher()

    public var recordedActions: [CallActions] = []

    public var isMuted: Bool = false
    public var isOnHold: Bool = false

    public enum CallActions: String {
        case connect
        case disconnect
        case toggleLocalVideo
        case toggleLocalAudio
        case toggleLocalCamera
        case muteLocalMedia
        case setOnHold
    }

    public init() {}

    public func connect() {
        recordedActions.append(.connect)
    }

    public func disconnect() async throws {
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

    public func muteLocalMedia(_ isMuted: Bool) {
        self.isMuted = isMuted
        recordedActions.append(.muteLocalMedia)
    }

    public func setOnHold(_ isOnHold: Bool) {
        self.isOnHold = isOnHold
        recordedActions.append(.setOnHold)
    }
}
