//
//  Created by Vonage on 18/6/26.
//

import Foundation
import SwiftUI
import VERACommonUI

extension NoiseSuppressionViewModel: BottomItemPresentable {
    public var id: String { "noise-suppression-button" }

    public var label: String {
        String(localized: "Noise Suppression", bundle: .veraAudioEffects)
    }

    public var accessibilityIdentifier: String? {
        nil
    }

    public var image: Image {
        state.image
    }

    public var isActive: Bool {
        state.isEnabled
    }

    public var accessory: BottomBarButtonAccessory? {
        nil
    }

    public func performAction() {
        onTap()
    }
}
