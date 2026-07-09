//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERADomain

struct MeetingRoomContent: View {

    let participants: [UIParticipant]
    let layout: MeetingRoomLayout
    let activeSpeakerId: String?

    init(
        participants: [UIParticipant],
        layout: MeetingRoomLayout,
        activeSpeakerId: String?,
    ) {
        self.participants = participants
        self.layout = layout
        self.activeSpeakerId = activeSpeakerId
    }

    var body: some View {
        if layout == .grid {
            AdaptiveGridLayout(
                participants: participants,
                activeSpeakerId: activeSpeakerId)
        } else {
            ActiveSpeakerLayout(
                participants: participants,
                activeSpeakerId: activeSpeakerId)
        }
    }
}

#Preview {
    MeetingRoomContent(
        participants: [],
        layout: .grid,
        activeSpeakerId: nil)
}
