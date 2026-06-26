//
//  Created by Vonage on 18/6/26.
//

import SwiftUI
import VERACommonUI
import VERAFeedback

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
