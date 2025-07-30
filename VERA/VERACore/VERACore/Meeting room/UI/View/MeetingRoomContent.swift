//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct MeetingRoomContent: View {

    let participants: [Participant]
    let showBottomSheet: Bool

    init(participants: [Participant], showBottomSheet: Bool) {
        self.participants = participants
        self.showBottomSheet = showBottomSheet
    }

    var body: some View {
        AdaptiveGrid(participants: participants)
    }
}

#Preview {
    MeetingRoomContent(participants: [], showBottomSheet: false)
}
