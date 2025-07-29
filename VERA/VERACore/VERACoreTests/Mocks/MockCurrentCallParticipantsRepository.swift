//
//  Created by Vonage on 29/7/25.
//

import Combine
import Foundation
import VERACore

class MockCurrentCallParticipantsRepository: CurrentCallParticipantsRepository {
    let participantsSubject = CurrentValueSubject<[VERACore.Participant], Never>([])

    func getCurrentCallParticipants() -> AnyPublisher<[VERACore.Participant], Never> {
        participantsSubject.eraseToAnyPublisher()
    }

    func updateParticipants(_ participants: [VERACore.Participant]) {
        participantsSubject.value = participants
    }
}
