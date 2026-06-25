//
//  Created by Vonage on 18/6/26.
//

import Combine
import SwiftUI
import VERACommonUI
import VERAScreenShare

@MainActor
struct ScreenShareBottomItemPresenter: BottomItemPresentable {
    private let actionTrigger = PassthroughSubject<Void, Never>()
    private let extensionId: String

    init(extensionId: String) {
        self.extensionId = extensionId
    }

    var id: String { "screen-share-button" }
    var label: String { String(localized: "Share Screen", bundle: .veraScreenShare) }
    var accessibilityIdentifier: String? { nil }
    var image: Image { VERACommonUIAsset.Images.screenShareSolid.swiftUIImage }
    var isActive: Bool { false }
    var accessory: BottomBarButtonAccessory? {
        .init(placement: .hiddenInteractionLayer) {
            BroadcastPickerRepresentable(
                preferredExtension: extensionId,
                actionTrigger: actionTrigger
            )
        }
    }

    func performAction() {
        actionTrigger.send()
    }
}
