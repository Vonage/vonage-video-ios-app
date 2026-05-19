//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Layout constants for the participants badge button.
private enum ParticipantsBadgeButtonConstants {
    /// Minimum diameter of the badge circle for normal counts.
    static let badgeSizeSmall: CGFloat = 20
    /// Minimum diameter of the badge circle for overflow counts.
    static let badgeSizeLarge: CGFloat = 24
    /// Horizontal offset of the badge from the button edge.
    static let badgeOffsetX: CGFloat = 5
    /// Vertical offset of the badge from the button edge.
    static let badgeOffsetY: CGFloat = -5
    /// Scale factor applied when count exceeds the maximum.
    static let overflowScale: CGFloat = 0.9
    /// Duration of the badge animation.
    static let animationDuration: Double = 0.2
}

struct ParticipantsBadgeButton: View {

    @Environment(\.meetingRoomTheme) private var theme

    private let participantsCount: Int
    private let onToggleParticipants: () -> Void

    init(participantsCount: Int, onToggleParticipants: @escaping () -> Void) {
        self.participantsCount = participantsCount
        self.onToggleParticipants = onToggleParticipants
    }

    var body: some View {
        ControlImageButton(
            isActive: true,
            image: VERACommonUIAsset.Images.group2Solid.swiftUIImage,
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
                        .fill(theme.vGray3)
                )
                .scaleEffect(
                    participantsCount > maxBadgeCount
                        ? ParticipantsBadgeButtonConstants.overflowScale : 1.0
                )
                .offset(
                    x: ParticipantsBadgeButtonConstants.badgeOffsetX,
                    y: ParticipantsBadgeButtonConstants.badgeOffsetY
                )
                .animation(
                    .easeInOut(duration: ParticipantsBadgeButtonConstants.animationDuration),
                    value: participantsCount
                )
        }
    }

    private var badgeText: String {
        participantsCount > maxBadgeCount ? "\(maxBadgeCount)+" : "\(participantsCount)"
    }

    private var badgeSize: CGFloat {
        participantsCount > maxBadgeCount
            ? ParticipantsBadgeButtonConstants.badgeSizeLarge
            : ParticipantsBadgeButtonConstants.badgeSizeSmall
    }
}

#Preview {
    ParticipantsBadgeButton(participantsCount: 25) {}
}
