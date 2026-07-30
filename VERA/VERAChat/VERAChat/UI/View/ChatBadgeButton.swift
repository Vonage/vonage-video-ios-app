//
//  Created by Vonage on 14/10/25.
//

import SwiftUI
import VERACommonUI

public struct ChatBadgeButton: View {

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
            BadgeView(badgeCount: unreadMessagesCount),
            alignment: .topTrailing
        )
    }
}

#Preview {
    ChatBadgeButton(unreadMessagesCount: 25) {}
}
