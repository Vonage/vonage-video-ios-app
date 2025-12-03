//
//  Created by Vonage on 14/10/25.
//

import SwiftUI
import VERACommonUI

struct ChatBadgeButton: View {

    private let unreadMessagesCount: Int
    private let onShowChat: () -> Void

    init(unreadMessagesCount: Int, onShowChat: @escaping () -> Void) {
        self.unreadMessagesCount = unreadMessagesCount
        self.onShowChat = onShowChat
    }

    var body: some View {
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
                        .fill(VERACommonUIAsset.Colors.vGray3.swiftUIColor)
                )
                .scaleEffect(unreadMessagesCount > MaxBadgeCount ? 0.9 : 1.0)
                .offset(x: 5, y: -5)
                .animation(.easeInOut(duration: 0.2), value: unreadMessagesCount)
        }
    }

    private var badgeText: String {
        unreadMessagesCount > MaxBadgeCount ? "\(MaxBadgeCount)+" : "\(unreadMessagesCount)"
    }

    private var badgeSize: CGFloat {
        unreadMessagesCount > MaxBadgeCount ? 24 : 20
    }
}

#Preview {
    ChatBadgeButton(unreadMessagesCount: 25) {}
}
