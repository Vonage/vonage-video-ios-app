//
//  Created by Vonage on 21/6/26.
//

import VERADomain

enum PipMeetingRoomParticipantResolver {
    static func pipParticipant(from state: MeetingRoomState) -> UIParticipant? {
        let remoteParticipants = state.participants
            .filter { !$0.isScreenshare }
            .sorted { $0.participant.creationTime < $1.participant.creationTime }

        guard !remoteParticipants.isEmpty else {
            return state.participants.first
        }

        if let first = remoteParticipants.first, first.isCameraEnabled {
            return first
        }

        return remoteParticipants.first(where: { $0.isCameraEnabled }) ?? remoteParticipants.first
    }
}
