//
//  Created by Vonage on 23/7/25.
//

import Combine

public protocol CurrentCallParticipantsRepository {
    func getCurrentCallParticipants() -> AnyPublisher<[Participant], Never>
    func updateParticipants(_ participants: [Participant])
}
