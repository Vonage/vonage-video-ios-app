//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct MeetingRoomContent: View {

    let participants: [Participant]
    let showBottomSheet: Bool
    let layout: MeetingRoomLayout

    init(
        participants: [Participant],
        showBottomSheet: Bool,
        layout: MeetingRoomLayout
    ) {
        self.participants = participants
        self.showBottomSheet = showBottomSheet
        self.layout = layout
    }

    var body: some View {
        if layout == .grid {
            GridLayout(participants: participants)
        } else {
            ActiveSpeakerLayout(participants: participants)
        }
    }
}

#Preview {
    MeetingRoomContent(
        participants: [],
        showBottomSheet: false,
        layout: .grid)
}
