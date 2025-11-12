//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI

struct ParticipantsBadgeButton: View {

    private let participantsCount: Int
    private let onToggleParticipants: () -> Void

    init(participantsCount: Int, onToggleParticipants: @escaping () -> Void) {
        self.participantsCount = participantsCount
        self.onToggleParticipants = onToggleParticipants
    }

    var body: some View {
        ControlImageButton(
            isActive: true,
            image: VERACommonUIAsset.group2Solid.swiftUIImage,
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
                        .fill(VERACommonUIAsset.vGray3.swiftUIColor)
                )
                .scaleEffect(participantsCount > MaxBadgeCount ? 0.9 : 1.0)
                .offset(x: 5, y: -5)
                .animation(.easeInOut(duration: 0.2), value: participantsCount)
        }
    }

    private var badgeText: String {
        participantsCount > MaxBadgeCount ? "\(MaxBadgeCount)+" : "\(participantsCount)"
    }

    private var badgeSize: CGFloat {
        participantsCount > MaxBadgeCount ? 24 : 20
    }
}

#Preview {
    ParticipantsBadgeButton(participantsCount: 25, onToggleParticipants: {})
}
