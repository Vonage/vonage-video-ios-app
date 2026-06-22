//
//  Created by Vonage on 18/6/26.
//

import Foundation
import SwiftUI
import VERACommonUI

extension ChatBadgeButtonViewModel: BottomItemPresentable {
    public var id: String { "chat-button" }

    public var label: String {
        String(localized: "Chat", bundle: .veraChat)
    }

    public var accessibilityIdentifier: String? {
        nil
    }

    public var image: Image {
        VERACommonUIAsset.Images.chat2Solid.swiftUIImage
    }

    public var isActive: Bool {
        false
    }

    public var accessory: BottomBarButtonAccessory? {
        let unreadMessagesCount = self.unreadMessagesCount
        guard unreadMessagesCount > 0 else { return nil }
        return BottomBarButtonAccessory(placement: .topTrailing) {
            BadgeView(badgeCount: unreadMessagesCount)
        }
    }

    public func performAction() {
        chatDidOpen()
    }
}
