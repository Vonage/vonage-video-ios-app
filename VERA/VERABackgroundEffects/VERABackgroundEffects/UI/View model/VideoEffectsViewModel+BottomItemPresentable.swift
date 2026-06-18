//
//  Created by Vonage on 18/6/26.
//

import Foundation
import SwiftUI
import VERACommonUI

extension VideoEffectsViewModel: BottomItemPresentable {
    public var id: String { "effects-button" }

    public var label: String {
        String(localized: "Effects", bundle: .module)
    }

    public var accessibilityIdentifier: String? {
        nil
    }

    public var image: Image {
        selectedEffect.image
    }

    public var isActive: Bool {
        selectedEffect != .none
    }

    public var accessory: BottomBarButtonAccessory? {
        nil
    }

    public func performAction() {
        isSheetPresented = true
    }
}
