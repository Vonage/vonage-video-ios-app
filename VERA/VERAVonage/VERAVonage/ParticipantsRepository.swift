//
//  Created by Vonage on 12/9/25.
//

import Foundation
import VERADomain

final actor ParticipantsRepository {
    private var participantStreams: [String: Participant] = [:]

    var all: [Participant] {
        Array(participantStreams.values)
    }

    func saveParticipant(_ participant: Participant) async {
        participantStreams[participant.id] = participant
    }

    /// Check and replace in one actor operation so removal cannot interleave with a late update.
    func updateExistingParticipant(_ participant: Participant) {
        guard participantStreams[participant.id] != nil else { return }
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
