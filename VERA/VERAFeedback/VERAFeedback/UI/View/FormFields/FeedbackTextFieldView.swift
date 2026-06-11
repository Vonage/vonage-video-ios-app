//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import VERACommonUI

struct FeedbackTextFieldView: View {

    private enum Layout {
        static let cornerRadius: CGFloat = BorderRadius.medium.value
        static let borderWidth: CGFloat = 1
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let errorColor = VERACommonUIAsset.SemanticColors.error.swiftUIColor
    }

    @ObservedObject var feedbackFieldViewModel: FeedbackFieldViewModel
    let showValidationErrors: Bool
    let fieldIndex: Int
    var focusedFieldIndex: FocusState<Int?>.Binding

    private var showsError: Bool {
        showValidationErrors && !feedbackFieldViewModel.isValid
    }

    private var borderColor: Color {
        showsError
            ? Layout.errorColor
            : VERACommonUIAsset.SemanticColors.border.swiftUIColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(feedbackFieldViewModel.title)

            fieldContent

            if showsError, let message = feedbackFieldViewModel.validationMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Layout.errorColor)
            } else if let maxChars = feedbackFieldViewModel.maxChars {
                HStack {
                    Spacer()
                    Text("\(feedbackFieldViewModel.value.count)/\(maxChars)")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .feedbackFieldListRowStyle()
    }

    @ViewBuilder
    private var fieldContent: some View {
        TextField("", text: $feedbackFieldViewModel.value, axis: .vertical)
            .textFieldStyle(.plain)
            .autocorrectionDisabled(true)
            .focused(focusedFieldIndex, equals: fieldIndex)
            .frame(minHeight: 30, maxHeight: 200)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)
            .background(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: Layout.borderWidth)
            }
            .animation(.easeInOut(duration: 0.2), value: showsError)
    }
}
