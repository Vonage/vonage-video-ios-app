//
//  Created by Vonage on 22/06/2026.
//

import SwiftUI
import VERADomain

private enum BadgeConstants {
    static let badgeSizeSmall: CGFloat = 20
    static let badgeSizeLarge: CGFloat = 24
    static let badgeOffsetX: CGFloat = 5
    static let badgeOffsetY: CGFloat = -5
    static let overflowScale: CGFloat = 0.9
    static let animationDuration: Double = 0.2
}

/// A compact badge that displays a numeric count.
///
/// `BadgeView` renders a themed circular counter for compact UI entry points,
/// such as bottom bar buttons, toolbar actions, or other icon-based controls.
/// The badge is hidden when the count is zero and caps large values using the
/// shared badge limit.
public struct BadgeView: View {
    @Environment(\.meetingRoomTheme) private var theme

    private let badgeCount: Int

    /// Creates a badge for the provided count.
    ///
    /// - Parameter badgeCount: The count to display. Values less than or equal
    ///   to zero render no badge.
    public init(badgeCount: Int) {
        self.badgeCount = badgeCount
    }

    public var body: some View {
        if badgeCount > 0 {
            Text(badgeText)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
                .frame(minWidth: badgeSize, minHeight: badgeSize)
                .background(
                    Circle()
                        .fill(theme.vGray3)
                )
                .scaleEffect(
                    badgeCount > maxBadgeCount
                        ? BadgeConstants.overflowScale : 1.0
                )
                .offset(
                    x: BadgeConstants.badgeOffsetX,
                    y: BadgeConstants.badgeOffsetY
                )
                .animation(
                    .easeInOut(duration: BadgeConstants.animationDuration),
                    value: badgeCount
                )
        }
    }

    private var badgeText: String {
        badgeCount > maxBadgeCount ? "\(maxBadgeCount)+" : "\(badgeCount)"
    }

    private var badgeSize: CGFloat {
        badgeCount > maxBadgeCount
            ? BadgeConstants.badgeSizeLarge
            : BadgeConstants.badgeSizeSmall
    }
}

#Preview {
    BadgeView(badgeCount: 25)
}
