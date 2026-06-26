//
//  Created by Vonage on 18/6/26.
//

import SwiftUI
import VERACommonUI
import VERASettings

@MainActor
struct SettingsBottomItemPresenter: BottomItemPresentable {
    let onShowSettings: () -> Void

    var id: String { "settings-button" }
    var label: String { String(localized: "Settings", bundle: .veraSettings) }
    var accessibilityIdentifier: String? { nil }
    var image: Image { VERACommonUIAsset.Images.gearSolid.swiftUIImage }
    var isActive: Bool { false }
    var accessory: BottomBarButtonAccessory? { nil }
    var overflowSelectionBehavior: BottomBarOverflowSelectionBehavior { .dismissBeforeAction }

    func performAction() {
        onShowSettings()
    }
}
