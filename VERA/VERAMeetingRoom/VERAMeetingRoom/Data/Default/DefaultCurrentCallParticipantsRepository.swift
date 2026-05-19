//
//  Created by Vonage on 23/7/25.
//

import Combine
import VERADomain

public class DefaultCurrentCallParticipantsRepository: CurrentCallParticipantsRepository {

    private let _participants = CurrentValueSubject<[Participant], Never>([])

    public init() {}

    public func getCurrentCallParticipants() -> AnyPublisher<[Participant], Never> {
        _participants.eraseToAnyPublisher()
    }

    public func updateParticipants(_ participants: [Participant]) {
        _participants.value = participants
    }
}
