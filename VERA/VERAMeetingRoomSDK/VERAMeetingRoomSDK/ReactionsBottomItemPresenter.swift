//
//  Created by Vonage on 18/6/26.
//

import SwiftUI
import VERACommonUI
import VERAReactions

@MainActor
struct ReactionsBottomItemPresenter: BottomItemPresentable {
    let isPickerPresented: Bool
    let viewModel: EmojiButtonContainerViewModel
    let onShowPickerView: () -> Void

    var id: String { "reactions-button" }
    var label: String { String(localized: "Reactions", bundle: .veraReactions) }
    var accessibilityIdentifier: String? { nil }
    var image: Image { VERACommonUIAsset.Images.emojiSolid.swiftUIImage }
    var isActive: Bool { isPickerPresented }
    var accessory: BottomBarButtonAccessory? { nil }
    var overflowPresentation: BottomBarOverflowPresentation {
        .headerContent {
            AnyView(EmojiHorizontalPickerViewContainer(viewModel: viewModel.pickerViewModel))
        }
    }

    func performAction() {
        onShowPickerView()
    }
}
