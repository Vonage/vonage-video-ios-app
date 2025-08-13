//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct ParticipantsBadgeButton: View {

    private let participantsCount: Int
    private let onToggleParticipants: () -> Void

    init(participantsCount: Int, onToggleParticipants: @escaping () -> Void) {
        self.participantsCount = participantsCount
        self.onToggleParticipants = onToggleParticipants
    }

    var body: some View {
        ControlButton(
            isActive: true,
            iconName: "person.2.fill",
            action: onToggleParticipants
        )
        .overlay(
            badgeView,
            alignment: .topTrailing
        )
    }

    @ViewBuilder
    private var badgeView: some View {
        if participantsCount > 0 {
            Text(badgeText)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
                .frame(minWidth: badgeSize, minHeight: badgeSize)
                .background(
                    Circle()
                        .fill(.vGray3)
                )
                .scaleEffect(participantsCount > 99 ? 0.9 : 1.0)
                .offset(x: 5, y: -5)
                .animation(.easeInOut(duration: 0.2), value: participantsCount)
        }
    }

    private var badgeText: String {
        participantsCount > 99 ? "99+" : "\(participantsCount)"
    }

    private var badgeSize: CGFloat {
        participantsCount > 99 ? 24 : 20
    }
}

#Preview {
    ParticipantsBadgeButton(participantsCount: 25, onToggleParticipants: {})
}
