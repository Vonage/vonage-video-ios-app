//
//  Created by Vonage on 18/6/26.
//

import SwiftUI
import VERACommonUI

extension ArchiveButtonViewModel: BottomItemPresentable {
    public var id: String { "archive-button" }

    public var label: String {
        state.bottomBarLabel
    }

    public var accessibilityIdentifier: String? {
        state.bottomBarAccessibilityIdentifier
    }

    public var image: Image {
        state.bottomBarImage
    }

    public var isActive: Bool {
        state.isArchiving
    }

    public var accessory: BottomBarButtonAccessory? {
        nil
    }

    public func performAction() {
        onTap()
    }
}
