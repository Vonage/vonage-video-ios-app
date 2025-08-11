//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation

public struct ParticipantsState: Equatable {
    public let localParticipant: Participant?
    public let participants: [Participant]

    public static var empty: ParticipantsState {
        ParticipantsState(localParticipant: nil, participants: [])
    }

    public init(
        localParticipant: Participant?,
        participants: [Participant]
    ) {
        self.localParticipant = localParticipant
        self.participants = participants
    }
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

public protocol CallConnectable: AnyObject {
    func connect()
    func disconnect()
}

public protocol MediaToggleable: AnyObject {
    func toggleLocalVideo()
    func toggleLocalCamera()
    func toggleLocalAudio()
}

public typealias CallFacade =
    ParticipantsPublisherProvider & EventsPublisherProvider & SessionStatePublisherProvider & CallConnectable
    & MediaToggleable
