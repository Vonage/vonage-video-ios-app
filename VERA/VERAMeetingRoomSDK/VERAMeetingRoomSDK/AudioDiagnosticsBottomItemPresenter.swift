//
//  Created by Vonage on 06/07/26.
//

import SwiftUI
import VERAAudioDiagnostics
import VERACommonUI

@MainActor
struct AudioDiagnosticsBottomItemPresenter: BottomItemPresentable {
    let onShowAudioDiagnostics: () -> Void

    var id: String { "audio-diagnostics-button" }
    var label: String { String(localized: "Audio Test", bundle: .module) }
    var accessibilityIdentifier: String? { AudioDiagnosticsAccessibilityID.meetingRoomButton }
    var image: Image { VERACommonUIAsset.Images.audioMaxSolid.swiftUIImage }
    var isActive: Bool { false }
    var accessory: BottomBarButtonAccessory? { nil }
    var overflowSelectionBehavior: BottomBarOverflowSelectionBehavior { .dismissBeforeAction }

    func performAction() {
        onShowAudioDiagnostics()
    }
}
