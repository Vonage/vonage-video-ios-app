//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERADomain

@MainActor
struct MeetingRoomContent: View {
    @State private var selfViewCorner = FloatingSelfViewCorner.bottomRight
    let selfViewBottomInset: CGFloat

    var oneToOneParticipants: OneToOneParticipants? { OneToOneParticipants(participants: participants) }

    let participants: [UIParticipant]
    let layout: MeetingRoomLayout
    let activeSpeakerId: String?

    init(
        participants: [UIParticipant],
        layout: MeetingRoomLayout,
        activeSpeakerId: String?,
        selfViewBottomInset: CGFloat = 0
    ) {
        self.selfViewBottomInset = selfViewBottomInset
        self.participants = participants
        self.layout = layout
        self.activeSpeakerId = activeSpeakerId
    }

    var body: some View {
        if let pair = oneToOneParticipants {
            OneToOneCallLayout(
                participants: pair,
                corner: $selfViewCorner,
                bottomInset: selfViewBottomInset
            )
        } else if layout == .grid {
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
