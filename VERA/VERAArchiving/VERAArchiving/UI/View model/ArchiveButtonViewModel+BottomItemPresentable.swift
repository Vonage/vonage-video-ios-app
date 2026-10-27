//
//  Created by Vonage on 18/6/26.
//

import SwiftUI
import VERACommonUI

extension ArchiveButtonViewModel: BottomItemPresentable {
    public var id: String { kind.bottomBarItemID }

    public var label: String {
        kind.bottomBarLabel(for: state)
    }

    public var accessibilityIdentifier: String? {
        kind.bottomBarAccessibilityIdentifier(for: state)
    }

    public var image: Image {
        kind.bottomBarImage(for: state)
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
