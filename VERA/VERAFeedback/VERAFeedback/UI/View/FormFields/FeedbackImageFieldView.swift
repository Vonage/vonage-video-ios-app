//
//  Created by Vonage on 10/06/2026.
//

import PhotosUI
import SwiftUI
import VERACommonUI

struct FeedbackImageFieldView: View {

    private enum Layout {
        static let spacing: CGFloat = 12
        static let previewMaxHeight: CGFloat = 200
        static let previewCornerRadius: CGFloat = 8
    }

    @ObservedObject var feedbackFieldViewModel: FeedbackFieldViewModel
    let showValidationErrors: Bool
    var onImagePicked: (() -> Void)? = nil
    @State private var isPhotoLibraryPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var primaryColor: Color {
        VERACommonUIAsset.SemanticColors.primary.swiftUIColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            Text(feedbackFieldViewModel.value)
                .font(.body)
                .foregroundStyle(.primary)

            OutlinedButton(
                text: Text(String(localized: "Capture screenshot")),
                color: primaryColor,
                onAction: { captureScreenshot() }
            )

            OutlinedButton(
                text: Text(String(localized: "Add image from photo library")),
                color: primaryColor,
                onAction: { isPhotoLibraryPresented = true }
            )

            if let image = feedbackFieldViewModel.attachedImage {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: Layout.previewMaxHeight)
                    .clipShape(
                        RoundedRectangle(cornerRadius: Layout.previewCornerRadius, style: .continuous)
                    )
                VStack(alignment: .leading) {
                    Button(action: {
                        feedbackFieldViewModel.attachedImage = nil
                    }) {
                        HStack {
                            VERACommonUIAsset.Images.removeLine.swiftUIImage
                            Text(String(localized: "Remove image"))
                        }
                    }

                }
            }

            if showValidationErrors,
                !feedbackFieldViewModel.isValid,
                let message = feedbackFieldViewModel.validationMessage
            {
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
        .onChange(of: selectedPhotoItem) { newItem in
            loadPhoto(from: newItem)
        }
    }

    private func captureScreenshot() {
        guard let image = FeedbackScreenshotCapturer.captureContentBehindModal() else { return }
        feedbackFieldViewModel.attachedImage = image
        onImagePicked?()
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                let image = PlatformImageFactory.image(from: data)
            else { return }
            await MainActor.run {
                feedbackFieldViewModel.attachedImage = image
                onImagePicked?()
            }
        }
    }
}
