//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation

public protocol ParticipantsPublisherProvider: AnyObject {
    var participantsPublisher: AnyPublisher<[Participant], Never> { get }
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
    func toggleLocalAudio()
}

public typealias CallFacade =
    ParticipantsPublisherProvider & EventsPublisherProvider & SessionStatePublisherProvider & CallConnectable
    & MediaToggleable
