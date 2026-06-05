//
//  Created by Vonage on 05/06/2026.
//

import Combine
import SwiftUI
import VERACommonUI
import VERADomain

public struct FeedbackComponentButton: View {
//    @ObservedObject private var viewModel: ChatBadgeButtonViewModel
    private let onShowFeedbackForm: () -> Void

//    private var unreadMessagesCount: Int { viewModel.unreadMessagesCount }

    public init(onShowFeedbackForm: @escaping () -> Void) {
//        self.viewModel = viewModel
        self.onShowFeedbackForm = onShowFeedbackForm
    }

    public var body: some View {
        FeedbackButton(
            onShowFeedbackForm: onShowFeedbackForm
        )
    }
}
public struct FeedbackButton: View {

    /// Closure invoked when the gear button is tapped.
    /// The caller should present the settings view in response.
    private let onShowFeedbackForm: () -> Void

    /// Creates a new meeting room settings button.
    ///
    /// - Parameter onShowSettings: Optional closure called when the button is tapped.
    ///                             Typically provided by the parent view to handle sheet presentation.
    public init(onShowFeedbackForm: @escaping () -> Void) {
//        self.viewModel = viewModel
        self.onShowFeedbackForm = onShowFeedbackForm
    }

    public var body: some View {
        OngoingActivityControlImageButton(
            isActive: false,
            image: VERACommonUIAsset.Images.feedbackLine.swiftUIImage,
            action: {
                onShowFeedbackForm()
            }
        )
    }
}
