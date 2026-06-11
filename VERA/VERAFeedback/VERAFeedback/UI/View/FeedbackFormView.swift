//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import VERACommonUI

struct FeedbackFormView: View {

    private enum Constants {
        static let topScrollInset: CGFloat = 15
        static let bottomScrollInset: CGFloat = 70
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let bottomListId = "bottomListId"
    }

    @ObservedObject var feedbackFormViewModel: FeedbackFormViewModel

    // Triggers for scroll interaction
    @State private var imagePickedTrigger: Int = 0
    @State private var didValidateTrigger: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            feedbackFieldsList
                .modifier(
                    FeedbackScrollContentInset(
                        topInset: Constants.topScrollInset,
                        bottomInset: Constants.bottomScrollInset
                    )
                )
            sendButton
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.verticalPadding)
                .background(Color(uiColor: .systemGroupedBackground))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    private var sendButton: some View {
        FilledButton(
            text: Text("Send"),
            onAction: {
                feedbackFormViewModel.onSubmit()
                if !feedbackFormViewModel.isValid {
                    didValidateTrigger += 1
                }
            }
        )
        .accessibilityIdentifier("send_button")
    }

    private var feedbackFieldsList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(feedbackFormViewModel.feedbackFields.indices, id: \.self) { index in
                    let field = feedbackFormViewModel.feedbackFields[index]
                    switch field.type {
                    case .text:
                        FeedbackTextFieldView(
                            feedbackFieldViewModel: feedbackFormViewModel.feedbackFields[index],
                            showValidationErrors: feedbackFormViewModel.showValidationErrors
                        )
                        .id(index)
                    case .info:
                        FeedbackInfoFieldView(
                            feedbackFieldViewModel: feedbackFormViewModel.feedbackFields[index]
                        )
                        .id(index)
                    case .image:
                        FeedbackImageFieldView(
                            feedbackFieldViewModel: feedbackFormViewModel.feedbackFields[index],
                            showValidationErrors: feedbackFormViewModel.showValidationErrors,
                            onImagePicked: {
                                imagePickedTrigger += 1
                            }
                        )
                        .id(index)
                    }
                }
                Color.clear.frame(height: 1)
                    .feedbackFieldListRowStyle()
                    .id(Constants.bottomListId)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .environment(\.defaultMinListRowHeight, 0)
            .onChange(of: imagePickedTrigger) { _ in
                let lastIndex = feedbackFormViewModel.feedbackFields.count - 1
                guard lastIndex >= 0 else { return }
                withAnimation {
                    proxy.scrollTo(Constants.bottomListId, anchor: .top)
                }
            }
            .onChange(of: didValidateTrigger) { _ in
                guard let firstIndex = feedbackFormViewModel.feedbackFields.firstIndex(where: { !$0.isValid }) else {
                    return
                }
                withAnimation {
                    proxy.scrollTo(firstIndex, anchor: .top)
                }
            }

        }
    }
}

private struct FeedbackScrollContentInset: ViewModifier {
    let topInset: CGFloat
    let bottomInset: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentMargins(.top, topInset, for: .scrollContent)
                .contentMargins(.bottom, bottomInset, for: .scrollContent)
        } else {
            content
                .padding(.top, topInset)
                .padding(.bottom, bottomInset)
        }
    }
}
