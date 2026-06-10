//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import PhotosUI
import UIKit
import VERASettings
import VERACommonUI

/// Adaptive feedback form presentation.
///
/// - **Regular width** (`horizontalSizeClass == .regular`): `NavigationSplitView` with a sidebar
///   and a detail pane containing the form fields.
/// - **Compact width**: A single `NavigationStack` with the form inline.
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ObservedObject var feedbackSectionViewModel: FeedbackSectionViewModel

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
                .navigationTitle(feedbackSectionViewModel.title)
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
            Label(feedbackSectionViewModel.title, systemImage: "exclamationmark.bubble")
        }
        .navigationTitle(String(localized: "Feedback"))
        .toolbar {
            closeToolbarItem
        }
    }

    private var feedbackForm: some View {
        FeedbackSectionView(feedbackSectionViewModel: feedbackSectionViewModel)
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

/// Wrapper view that owns the feedback view model via `@StateObject`.
///
/// `@StateObject` ensures the view model is created once when the sheet
/// appears and survives any parent re-renders while the sheet is presented.
struct FeedbackSheetContent: View {
    @StateObject private var feedbackSectionViewModel = FeedbackSectionViewModel()

    var body: some View {
        FeedbackView(feedbackSectionViewModel: feedbackSectionViewModel)
    }
}

struct FeedbackSectionView: View {

    private enum Layout {
        static let topInset: CGFloat = 15
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
    }

    @ObservedObject var feedbackSectionViewModel: FeedbackSectionViewModel

    var body: some View {
        VStack {
            feedbackFieldsList
                .modifier(ScrollContentTopInset(height: Layout.topInset))
            sendButton
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.verticalPadding)
                .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    private var sendButton: some View {
        FilledButton(
            text: Text("Send"),
            onAction: feedbackSectionViewModel.onSubmit
        )
        .accessibilityIdentifier("send_button")
    }

    private var feedbackFieldsList: some View {
        List {
            ForEach(feedbackSectionViewModel.feedbackFields.indices, id: \.self) { index in
                let field = feedbackSectionViewModel.feedbackFields[index]
                switch field.type {
                case .text:
                    FeedbackTextFieldView(
                        feedbackFieldViewModel: feedbackSectionViewModel.feedbackFields[index],
                        showValidationErrors: feedbackSectionViewModel.showValidationErrors
                    )
                case .info:
                    FeedbackInfoFieldView(
                        feedbackFieldViewModel: feedbackSectionViewModel.feedbackFields[index]
                    )
                case .image:
                    FeedbackImageFieldView(
                        feedbackFieldViewModel: feedbackSectionViewModel.feedbackFields[index],
                        showValidationErrors: feedbackSectionViewModel.showValidationErrors
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .environment(\.defaultMinListRowHeight, 0)
    }
}

private struct FeedbackFieldListRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

private extension View {
    func feedbackFieldListRowStyle() -> some View {
        modifier(FeedbackFieldListRowStyle())
    }
}

private struct ScrollContentTopInset: ViewModifier {
    let height: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.contentMargins(.top, height, for: .scrollContent)
        } else {
            content.padding(.top, height)
        }
    }
}

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
                .foregroundStyle(.secondary)

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

struct FeedbackInfoFieldView: View {

    @ObservedObject var feedbackFieldViewModel: FeedbackFieldViewModel

    var body: some View {
        Text(feedbackFieldViewModel.value)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .feedbackFieldListRowStyle()
    }
}

struct FeedbackImageFieldView: View {

    private enum Layout {
        static let spacing: CGFloat = 12
        static let previewMaxHeight: CGFloat = 200
        static let previewCornerRadius: CGFloat = 8
    }

    @ObservedObject var feedbackFieldViewModel: FeedbackFieldViewModel
    let showValidationErrors: Bool
    @State private var isPhotoLibraryPresented = false
    @State private var isCameraPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var primaryColor: Color {
        VERACommonUIAsset.SemanticColors.primary.swiftUIColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            Text(feedbackFieldViewModel.value)
                .font(.body)
                .foregroundStyle(.primary)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                OutlinedButton(
                    text: Text(String(localized: "Capture screenshot")),
                    color: primaryColor,
                    onAction: { isCameraPresented = true }
                )
            }

            OutlinedButton(
                text: Text(String(localized: "Add screenshot")),
                color: primaryColor,
                onAction: { isPhotoLibraryPresented = true }
            )

            if let image = feedbackFieldViewModel.attachedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: Layout.previewMaxHeight)
                    .clipShape(
                        RoundedRectangle(cornerRadius: Layout.previewCornerRadius, style: .continuous)
                    )
            }

            if showValidationErrors,
               !feedbackFieldViewModel.isValid,
               let message = feedbackFieldViewModel.validationMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
            }
        }
        .feedbackFieldListRowStyle()
        .photosPicker(
            isPresented: $isPhotoLibraryPresented,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraImagePicker { image in
                feedbackFieldViewModel.attachedImage = image
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) { newItem in
            loadPhoto(from: newItem)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            await MainActor.run {
                feedbackFieldViewModel.attachedImage = image
            }
        }
    }
}
