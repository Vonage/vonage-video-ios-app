//
//  Created by Vonage on 18/6/26.
//

import Foundation
import SwiftUI
import VERACommonUI

extension CaptionsButtonViewModel: BottomItemPresentable {
    public var id: String { "captions-button" }

    public var label: String {
        String(localized: "Captions", bundle: .veraCaptions)
    }

    public var accessibilityIdentifier: String? {
        CaptionsAccessibilityID.toggleButton
    }

    public var image: Image {
        state.captionsEnabled
            ? VERACommonUIAsset.Images.closedCaptioningOffSolid.swiftUIImage
            : VERACommonUIAsset.Images.closedCaptioningSolid.swiftUIImage
    }

    public var isActive: Bool {
        state.captionsEnabled
    }

    public var accessory: BottomBarButtonAccessory? {
        nil
    }

    public func performAction() {
        onTap()
    }
}
