//
//  Created by Vonage on 23/7/25.
//

import Combine

@MainActor
public protocol CurrentCallParticipantsRepository: Sendable {
    func getCurrentCallParticipants() -> AnyPublisher<[Participant], Never>
    func updateParticipants(_ participants: [Participant])
}
