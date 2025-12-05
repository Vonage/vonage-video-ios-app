//
//  Created by Vonage on 12/9/25.
//

import Foundation
import VERACore
import VERADomain

final actor ParticipantsRepository {
    private var participantStreams: [String: Participant] = [:]

    var all: [Participant] {
        Array(participantStreams.values)
    }

    func saveParticipant(_ participant: Participant) async {
        participantStreams[participant.id] = participant
    }

    func getParticipant(id: String) async -> Participant? {
        participantStreams[id]
    }

    func removeParticipant(id: String) async {
        participantStreams.removeValue(forKey: id)
    }

    func reset() {
        participantStreams.removeAll()
    }
}
