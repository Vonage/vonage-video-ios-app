//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation

public struct ParticipantsState: Equatable {
    public let localParticipant: Participant?
    public let participants: [Participant]
    public let activeParticipantId: String?

    public static var empty: ParticipantsState {
        ParticipantsState(
            localParticipant: nil,
            participants: [],
            activeParticipantId: nil)
    }

    public init(
        localParticipant: Participant?,
        participants: [Participant],
        activeParticipantId: String?
    ) {
        self.localParticipant = localParticipant
        self.participants = participants
        self.activeParticipantId = activeParticipantId
    }
}

public enum CallState {
    case idle
    case connected
    case connecting
    case disconnecting
    case disconnected
}

public protocol ParticipantsPublisherProvider: AnyObject {
    var participantsPublisher: AnyPublisher<ParticipantsState, Never> { get }
}

public protocol EventsPublisherProvider: AnyObject {
    var eventsPublisher: AnyPublisher<SessionEvent, Never> { get }
}

public protocol SessionStatePublisherProvider: AnyObject {
    var statePublisher: AnyPublisher<SessionState, Never> { get }
}

public protocol CallStatePublisherProvider: AnyObject {
    var callState: AnyPublisher<CallState, Never> { get }
}

public protocol CallConnectable: AnyObject {
    func connect()
    func disconnect() async throws
}

public protocol MediaToggleable: AnyObject {
    var isMuted: Bool { get }

    func toggleLocalVideo()
    func toggleLocalCamera()
    func toggleLocalAudio()
    func muteLocalMedia(_ isMuted: Bool)
}

public protocol HoldeableCall: AnyObject {
    var isOnHold: Bool { get }

    func setOnHold(_ isOnHold: Bool)
}

public protocol CallFacade: AnyObject,
    ParticipantsPublisherProvider,
    EventsPublisherProvider,
    SessionStatePublisherProvider,
    CallConnectable,
    MediaToggleable,
    CallStatePublisherProvider,
    HoldeableCall {}
