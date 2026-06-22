//
//  Created by Vonage on 21/6/26.
//

import SwiftUI
import VERADomain

///
/// Minimal meeting room UI shown while Picture-in-Picture is active.
///
struct PipMeetingRoomView: View {
    let state: MeetingRoomState

    private var pipParticipant: UIParticipant? {
        PipMeetingRoomParticipantResolver.pipParticipant(from: state)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let participant = pipParticipant {
                ParticipantVideoCard(
                    participant: participant,
                    activeSpeakerId: state.activeSpeakerId
                )
            }
        }
    }
}

#Preview {
    PipMeetingRoomView(state: .initial)
}
