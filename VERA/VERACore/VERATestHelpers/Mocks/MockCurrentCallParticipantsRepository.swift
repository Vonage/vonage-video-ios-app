//
//  Created by Vonage on 29/7/25.
//

import Combine
import Foundation
import VERACore

public class MockCurrentCallParticipantsRepository: CurrentCallParticipantsRepository {
    public let participantsSubject = CurrentValueSubject<[VERACore.Participant], Never>([])

    public func getCurrentCallParticipants() -> AnyPublisher<[VERACore.Participant], Never> {
        participantsSubject.eraseToAnyPublisher()
    }

    public func updateParticipants(_ participants: [VERACore.Participant]) {
        participantsSubject.value = participants
    }
}

public func makeMockCurrentCallParticipantsRepository() -> MockCurrentCallParticipantsRepository {
    .init()
}
