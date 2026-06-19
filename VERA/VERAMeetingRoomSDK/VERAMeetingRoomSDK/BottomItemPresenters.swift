//
//  Created by Vonage on 18/6/26.
//

import Combine
import Foundation
import SwiftUI
import VERACommonUI
import VERAFeedback
import VERAReactions
import VERAScreenShare
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

@MainActor
struct FeedbackBottomItemPresenter: BottomItemPresentable {
    let onShowFeedbackForm: () -> Void

    var id: String { "feedback-button" }
    var label: String { String(localized: "Feedback", bundle: .veraFeedback) }
    var accessibilityIdentifier: String? { nil }
    var image: Image { VERACommonUIAsset.Images.feedbackLine.swiftUIImage }
    var isActive: Bool { false }
    var accessory: BottomBarButtonAccessory? { nil }
    var overflowSelectionBehavior: BottomBarOverflowSelectionBehavior { .dismissBeforeAction }

    func performAction() {
        onShowFeedbackForm()
    }
}

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
