//
//  Created by Vonage on 29/7/25.
//

import Combine
import Foundation
import VERACore
import VERADomain

public class MockCurrentCallParticipantsRepository: CurrentCallParticipantsRepository {
    public let participantsSubject = CurrentValueSubject<[Participant], Never>([])

    public func getCurrentCallParticipants() -> AnyPublisher<[Participant], Never> {
        participantsSubject.eraseToAnyPublisher()
    }

    public func updateParticipants(_ participants: [Participant]) {
        participantsSubject.value = participants
    }
}

public func makeMockCurrentCallParticipantsRepository() -> MockCurrentCallParticipantsRepository {
    .init()
}
