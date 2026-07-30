//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import VERACommonUI
import VERADomain

private enum FeedbackFormViewConstants {
    static let topSuccessViewInset: CGFloat = 50
    static let topScrollInset: CGFloat = 15
    static let bottomScrollInset: CGFloat = 70
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 12
    static let bottomErroViewInset: CGFloat = 20
    static let bottomListId = "bottomListId"
    static let sendAccessibilityId = "send_button"
}

struct FeedbackFormView: View {

    private static let successTitle = String(localized: "Your Jira ticket has been created.")
    private static let closeButtonTitle = String(localized: "Close")
    private static let sendButtonTitle = String(localized: "Send")
    private static let doneButtonTitle = String(localized: "Done")

    @Environment(\.dismiss) private var dismiss
    @Environment(\.meetingRoomTheme) private var theme

    @ObservedObject var feedbackFormViewModel: FeedbackFormViewModel

    @FocusState private var focusedFieldIndex: Int?

    // Triggers for scroll interaction
    @State private var imagePickedTrigger: Int = 0
    @State private var didValidateTrigger: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            if let feedbackResult = feedbackFormViewModel.feedbackResult {
                VStack {
                    feedbackSuccessView(result: feedbackResult)
                    Spacer()
                    closeButton
                        .padding(.horizontal, FeedbackFormViewConstants.horizontalPadding)
                        .padding(.vertical, FeedbackFormViewConstants.verticalPadding)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                .padding(.top, FeedbackFormViewConstants.topSuccessViewInset)
            } else {
                feedbackFieldsList
                    .modifier(
                        FeedbackScrollContentInset(
                            topInset: FeedbackFormViewConstants.topScrollInset,
                            bottomInset: FeedbackFormViewConstants.bottomScrollInset
                        )
                    )
                sendButton
                    .padding(.horizontal, FeedbackFormViewConstants.horizontalPadding)
                    .padding(.vertical, FeedbackFormViewConstants.verticalPadding)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }

            if feedbackFormViewModel.isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()

                ProgressView()
                    .controlSize(.large)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .toast(
            toast: $feedbackFormViewModel.toast,
            placement: .bottom,
            verticalPadding: FeedbackFormViewConstants.bottomErroViewInset
        )
    }

    private var closeButton: some View {
        FilledButton(
            text: Text(FeedbackFormView.closeButtonTitle),
            onAction: {
                dismiss()
            }
        )
        .disabled(feedbackFormViewModel.isLoading)
        .accessibilityIdentifier(FeedbackFormViewConstants.sendAccessibilityId)
    }

    private var sendButton: some View {
        FilledButton(
            text: Text(FeedbackFormView.sendButtonTitle),
            onAction: {
                feedbackFormViewModel.onSubmit()
                if !feedbackFormViewModel.isValid {
                    didValidateTrigger += 1
                }
            }
        )
        .disabled(feedbackFormViewModel.isLoading)
        .accessibilityIdentifier(FeedbackFormViewConstants.sendAccessibilityId)
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
                            showValidationErrors: feedbackFormViewModel.showValidationErrors,
                            fieldIndex: index,
                            focusedFieldIndex: $focusedFieldIndex
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
                        ) {
                            imagePickedTrigger += 1
                        }
                        .id(index)
                    }
                }
                Color.clear.frame(height: 1)
                    .feedbackFieldListRowStyle()
                    .id(FeedbackFormViewConstants.bottomListId)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.background)
            #if os(iOS)
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button(action: focusPrevious) {
                            Image(systemName: "chevron.up")
                        }
                        .disabled(
                            focusedFieldIndex == nil
                                || FeedbackFormFocusNavigation.isFirstTextFieldFocused(
                                    focusedFieldIndex: focusedFieldIndex,
                                    textFieldIndices: textFieldIndices
                                )
                        )

                        Button(action: focusNext) {
                            Image(systemName: "chevron.down")
                        }
                        .disabled(
                            focusedFieldIndex == nil
                                || FeedbackFormFocusNavigation.isLastTextFieldFocused(
                                    focusedFieldIndex: focusedFieldIndex,
                                    textFieldIndices: textFieldIndices
                                )
                        )

                        Spacer()

                        Button(FeedbackFormView.doneButtonTitle) {
                            focusedFieldIndex = nil
                        }
                    }
                }
            #endif
            .onChange(of: focusedFieldIndex) { fieldIndex in
                guard let fieldIndex else { return }
                withAnimation {
                    proxy.scrollTo(fieldIndex, anchor: .center)
                }
            }
            .onChange(of: imagePickedTrigger) { _ in
                withAnimation {
                    proxy.scrollTo(FeedbackFormViewConstants.bottomListId, anchor: .top)
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

    @ViewBuilder
    private func feedbackSuccessView(result: FeedbackReportResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(FeedbackFormView.successTitle)
            Link("\(result.ticketUrl)", destination: URL(string: result.ticketUrl)!)
                .foregroundStyle(theme.primary)
        }
    }

    private var textFieldIndices: [Int] {
        FeedbackFormFocusNavigation.textFieldIndices(in: feedbackFormViewModel.feedbackFields)
    }

    private func focusPrevious() {
        guard
            let newIndex = FeedbackFormFocusNavigation.focusPrevious(
                focusedFieldIndex: focusedFieldIndex,
                textFieldIndices: textFieldIndices
            )
        else { return }

        focusedFieldIndex = newIndex
    }

    private func focusNext() {
        guard
            let newIndex = FeedbackFormFocusNavigation.focusNext(
                focusedFieldIndex: focusedFieldIndex,
                textFieldIndices: textFieldIndices
            )
        else { return }

        focusedFieldIndex = newIndex
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
