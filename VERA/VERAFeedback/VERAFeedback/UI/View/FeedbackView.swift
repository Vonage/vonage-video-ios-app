//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import VERACommonUI

/// Adaptive feedback form presentation.
///
/// - **Regular width** (`horizontalSizeClass == .regular`): `NavigationSplitView` with a sidebar
///   and a detail pane containing the form fields.
/// - **Compact width**: A single `NavigationStack` with the form inline.
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ObservedObject var feedbackFormViewModel: FeedbackFormViewModel

    var body: some View {
        Group {
            if horizontalSizeClass?.isRegularLayout == true {
                regularLayout
            } else {
                compactLayout
            }
        }
    }

    // MARK: - Compact (iPhone)

    private var compactLayout: some View {
        NavigationStack {
            feedbackForm
                .navigationTitle(feedbackFormViewModel.title)
                .toolbar {
                    closeToolbarItem
                }
        }
    }

    // MARK: - Regular (iPad / Mac)

    private var regularLayout: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            feedbackForm
                .navigationTitle(String(localized: "Details"))
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        List {
            Label(feedbackFormViewModel.title, systemImage: "exclamationmark.bubble")
        }
        .navigationTitle(String(localized: "Feedback"))
        .toolbar {
            closeToolbarItem
        }
    }

    private var feedbackForm: some View {
        FeedbackFormView(feedbackFormViewModel: feedbackFormViewModel)
    }

    @ToolbarContentBuilder
    private var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(String(localized: "Close")) {
                dismiss()
            }
        }
    }
}
