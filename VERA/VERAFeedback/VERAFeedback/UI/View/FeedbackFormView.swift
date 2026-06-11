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
        static let sendAccessibilityId = "send_button"
    }

    @ObservedObject var feedbackFormViewModel: FeedbackFormViewModel
    @FocusState private var focusedFieldIndex: Int?

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
            text: Text(String(localized: "Send")),
            onAction: {
                feedbackFormViewModel.onSubmit()
                if !feedbackFormViewModel.isValid {
                    didValidateTrigger += 1
                }
            }
        )
        .accessibilityIdentifier(Constants.sendAccessibilityId)
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: focusPrevious) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(focusedFieldIndex == nil || isFirstTextFieldFocused)

                    Button(action: focusNext) {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(focusedFieldIndex == nil || isLastTextFieldFocused)

                    Spacer()

                    Button(String(localized: "Done")) {
                        focusedFieldIndex = nil
                    }
                }
            }
            .onChange(of: focusedFieldIndex) { fieldIndex in
                guard let fieldIndex else { return }
                withAnimation {
                    proxy.scrollTo(fieldIndex, anchor: .center)
                }
            }
            .onChange(of: imagePickedTrigger) { _ in
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

    private var textFieldIndices: [Int] {
        feedbackFormViewModel.feedbackFields.indices.filter {
            feedbackFormViewModel.feedbackFields[$0].type == .text
        }
    }

    private var isFirstTextFieldFocused: Bool {
        guard let focusedFieldIndex else { return false }
        return focusedFieldIndex == textFieldIndices.first
    }

    private var isLastTextFieldFocused: Bool {
        guard let focusedFieldIndex else { return false }
        return focusedFieldIndex == textFieldIndices.last
    }

    private func focusPrevious() {
        guard let focusedFieldIndex,
            let currentIndex = textFieldIndices.firstIndex(of: focusedFieldIndex),
            currentIndex > 0
        else { return }

        self.focusedFieldIndex = textFieldIndices[currentIndex - 1]
    }

    private func focusNext() {
        guard let focusedFieldIndex,
            let currentIndex = textFieldIndices.firstIndex(of: focusedFieldIndex),
            currentIndex < textFieldIndices.count - 1
        else { return }

        self.focusedFieldIndex = textFieldIndices[currentIndex + 1]
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

