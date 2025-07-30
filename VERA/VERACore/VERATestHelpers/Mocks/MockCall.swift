//
//  Created by Vonage on 29/7/25.
//

import Combine
import Foundation
import VERACore

public class MockCall: VERACore.CallFacade {
    public let _eventsPublisher = CurrentValueSubject<VERACore.SessionEvent, Never>(.idle)
    public lazy var eventsPublisher: AnyPublisher<VERACore.SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    public let _participantsPublisher = CurrentValueSubject<[VERACore.Participant], Never>([])
    public lazy var participantsPublisher: AnyPublisher<[VERACore.Participant], Never> =
        _participantsPublisher.eraseToAnyPublisher()

    public let _statePublisher = CurrentValueSubject<VERACore.SessionState, Never>(SessionState.default)
    public lazy var statePublisher: AnyPublisher<VERACore.SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    public init() {}

    public func connect() {
    }

    public func disconnect() {
    }

    public func toggleLocalVideo() {
    }

    public func toggleLocalAudio() {
    }
}
