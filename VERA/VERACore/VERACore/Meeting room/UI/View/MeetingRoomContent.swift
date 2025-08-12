//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct MeetingRoomContent: View {

    let participants: [Participant]
    let showBottomSheet: Bool
    let layout: MeetingRoomLayout
    let activeSpeakerId: String?

    init(
        participants: [Participant],
        showBottomSheet: Bool,
        layout: MeetingRoomLayout,
        activeSpeakerId: String?
    ) {
        self.participants = participants
        self.showBottomSheet = showBottomSheet
        self.layout = layout
        self.activeSpeakerId = activeSpeakerId
    }

    var body: some View {
        if layout == .grid {
            AdaptiveVideoGrid(
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
        showBottomSheet: false,
        layout: .grid,
        activeSpeakerId: nil)
}
