
struct FeedbackTextFieldView: View {

    private enum Layout {
        static let lineHeight: CGFloat = 21
        static let cornerRadius: CGFloat = BorderRadius.medium.value
        static let borderWidth: CGFloat = 1
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
    }

    private static let errorColor = VERACommonUIAsset.SemanticColors.error.swiftUIColor

    @ObservedObject var feedbackFieldViewModel: FeedbackFieldViewModel
    let showValidationErrors: Bool

    private var showsError: Bool {
        showValidationErrors && !feedbackFieldViewModel.isValid
    }

    private var borderColor: Color {
        showsError
            ? Self.errorColor
            : VERACommonUIAsset.SemanticColors.border.swiftUIColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(feedbackFieldViewModel.title)

            fieldContent
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.verticalPadding)
                .background(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: Layout.borderWidth)
                }
                .animation(.easeInOut(duration: 0.2), value: showsError)


            if showsError, let message = feedbackFieldViewModel.validationMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Self.errorColor)
            } else if let maxChars = feedbackFieldViewModel.maxChars {
                HStack {
                    Spacer()
                    Text("\(feedbackFieldViewModel.value.count)/\(maxChars)")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if let footer = feedbackFieldViewModel.footer, !footer.isEmpty {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .feedbackFieldListRowStyle()
    }

    @ViewBuilder
    private var fieldContent: some View {
        if let maxLineLimit = feedbackFieldViewModel.maxLineLimit {
            LimitedMultilineTextView(
                text: Binding(
                    get: { feedbackFieldViewModel.value },
                    set: { feedbackFieldViewModel.value = $0 }
                ),
                minLines: feedbackFieldViewModel.minLineLimit ?? 1,
                maxLines: maxLineLimit,
                maxCharacters: feedbackFieldViewModel.maxChars,
                lineHeight: Layout.lineHeight
            )
        } else {
            TextField("", text: $feedbackFieldViewModel.value, axis: .vertical)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .frame(maxHeight: 200)
        }
    }
}