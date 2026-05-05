//
//  Created by Vonage on 14/10/25.
//

import Combine
import SwiftUI
import VERACommonUI
import VERADomain

/// Layout constants for the chat badge button.
private enum ChatBadgeButtonConstants {
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

public struct ChatBadgeButton: View {

    @Environment(\.meetingRoomTheme) private var theme

    private let unreadMessagesCount: Int
    private let onShowChat: () -> Void

    public init(
        unreadMessagesCount: Int,
        onShowChat: @escaping () -> Void
    ) {
        self.unreadMessagesCount = unreadMessagesCount
        self.onShowChat = onShowChat
    }

    public var body: some View {
        ControlImageButton(
            isActive: true,
            image: VERACommonUIAsset.Images.chat2Solid.swiftUIImage,
            action: onShowChat
        )
        .overlay(
            badgeView,
            alignment: .topTrailing
        )
    }

    @ViewBuilder
    private var badgeView: some View {
        if unreadMessagesCount > 0 {
            Text(badgeText)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
                .frame(minWidth: badgeSize, minHeight: badgeSize)
                .background(
                    Circle()
                        .fill(theme.vGray3)
                )
                .scaleEffect(
                    unreadMessagesCount > maxBadgeCount
                        ? ChatBadgeButtonConstants.overflowScale : 1.0
                )
                .offset(
                    x: ChatBadgeButtonConstants.badgeOffsetX,
                    y: ChatBadgeButtonConstants.badgeOffsetY
                )
                .animation(
                    .easeInOut(duration: ChatBadgeButtonConstants.animationDuration),
                    value: unreadMessagesCount
                )
        }
    }

    private var badgeText: String {
        unreadMessagesCount > maxBadgeCount ? "\(maxBadgeCount)+" : "\(unreadMessagesCount)"
    }

    private var badgeSize: CGFloat {
        unreadMessagesCount > maxBadgeCount
            ? ChatBadgeButtonConstants.badgeSizeLarge
            : ChatBadgeButtonConstants.badgeSizeSmall
    }
}

#Preview {
    ChatBadgeButton(unreadMessagesCount: 25) {}
}
