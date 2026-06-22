//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct ParticipantsBadgeButton: View {

    @Environment(\.meetingRoomTheme) private var theme

    private let participantsCount: Int
    private let isActive: Bool
    private let onToggleParticipants: () -> Void

    init(
        participantsCount: Int,
        isActive: Bool = false,
        onToggleParticipants: @escaping () -> Void
    ) {
        self.participantsCount = participantsCount
        self.isActive = isActive
        self.onToggleParticipants = onToggleParticipants
    }

    var body: some View {
        BottomBarInlineButton(
            image: VERACommonUIAsset.Images.group2Solid.swiftUIImage,
            isActive: isActive,
            action: onToggleParticipants
        )
        .overlay(
            BadgeView(badgeCount: participantsCount),
            alignment: .topTrailing
        )
    }
}

#Preview {
    ParticipantsBadgeButton(participantsCount: 25) {}
}
