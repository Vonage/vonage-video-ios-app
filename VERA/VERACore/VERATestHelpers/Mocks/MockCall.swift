//
//  Created by Vonage on 29/7/25.
//

import Combine
import Foundation
import VERADomain

public class MockCall: CallFacade {

    public let _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(.idle)
    public lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    public let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(ParticipantsState.empty)
    public lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    public let _statePublisher = CurrentValueSubject<SessionState, Never>(SessionState.initial)
    public lazy var statePublisher: AnyPublisher<SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    public var _callState = CurrentValueSubject<CallState, Never>(CallState.idle)
    public lazy var callState: AnyPublisher<CallState, Never> = _callState.eraseToAnyPublisher()

    public var _archivingState = CurrentValueSubject<ArchivingState, Never>(ArchivingState.idle)
    public lazy var archivingState: AnyPublisher<ArchivingState, Never> = _archivingState.eraseToAnyPublisher()

    public var _captionsPublisher = CurrentValueSubject<[CaptionItem], Never>([])
    public lazy var captionsPublisher: AnyPublisher<[CaptionItem], Never> = _captionsPublisher.eraseToAnyPublisher()

    public var recordedActions: [CallActions] = []

    public var isMuted: Bool = false
    public var isOnHold: Bool = false
    public var areCaptionsEnabled = false

    public enum CallActions: String {
        case connect
        case disconnect
        case toggleLocalVideo
        case toggleLocalAudio
        case toggleLocalCamera
        case muteLocalMedia
        case setOnHold
        case enableCaptions
        case disableCaptions
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

    public func enableCaptions() async {
        areCaptionsEnabled = true
        recordedActions.append(.enableCaptions)
    }

    public func disableCaptions() async {
        areCaptionsEnabled = false
        recordedActions.append(.disableCaptions)
    }
}
