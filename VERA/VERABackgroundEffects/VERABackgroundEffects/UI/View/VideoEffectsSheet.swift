//
//  Created by Vonage on 31/05/2026.
//

import PhotosUI
import SwiftUI
import VERACommonUI
import VERADomain

/// Bottom sheet presenting all video effects: blur levels and background images.
///
/// Matches the Android `VideoEffectsSheet` for platform parity — a grid of blur tiles
/// followed by a grid of background thumbnails with an "Add image" tile.
public struct VideoEffectsSheet: View {

    @ObservedObject var viewModel: VideoEffectsViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []

    public init(viewModel: VideoEffectsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    effectsSection
                    backgroundsSection
                }
                .padding()
            }
            .navigationTitle(String(localized: "Video effects", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.loadBackgrounds() }
        }
    }

    // MARK: - Effects Section

    @ViewBuilder
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Effects", bundle: .module))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                effectTile(
                    effect: .none,
                    image: VideoEffect.none.image,
                    label: VideoEffect.none.label
                )
                effectTile(
                    effect: .blurLow,
                    image: VideoEffect.blurLow.image,
                    label: VideoEffect.blurLow.label
                )
                effectTile(
                    effect: .blurHigh,
                    image: VideoEffect.blurHigh.image,
                    label: VideoEffect.blurHigh.label
                )
            }
        }
    }

    @ViewBuilder
    private func effectTile(effect: VideoEffect, image: Image, label: String) -> some View {
        let isSelected = viewModel.selectedEffect == effect
        Button {
            viewModel.selectEffect(effect)
        } label: {
            VStack(spacing: 6) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                isSelected
                                    ? VERACommonUIAsset.SemanticColors.primary.swiftUIColor.opacity(0.15)
                                    : Color(.systemGray6))
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected
                                    ? VERACommonUIAsset.SemanticColors.primary.swiftUIColor
                                    : .clear,
                                lineWidth: 2
                            )
                    )
                Text(label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Backgrounds Section

    private var backgroundColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]
    }

    @ViewBuilder
    private var backgroundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Backgrounds", bundle: .module))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: backgroundColumns, spacing: 12) {
                ForEach(viewModel.backgrounds) { item in
                    backgroundTile(item)
                }
                addImageTile
            }
        }
    }

    @ViewBuilder
    private func backgroundTile(_ item: VideoBackgroundItem) -> some View {
        let isSelected: Bool = {
            if case .backgroundImage(let id, _) = viewModel.selectedEffect {
                return id == item.id
            }
            return false
        }()

        Button {
            viewModel.selectBackground(item)
        } label: {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .overlay {
                    backgroundThumbnail(item)
                }
                .clipped()
                .contentShape(Rectangle())
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isSelected
                                ? VERACommonUIAsset.SemanticColors.primary.swiftUIColor
                                : .clear,
                            lineWidth: 2
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.id)
        .overlay(alignment: .topTrailing) {
            if item.isUserUploaded {
                deleteOverlay(item)
            }
        }
    }

    @ViewBuilder
    private func backgroundThumbnail(_ item: VideoBackgroundItem) -> some View {
        if let resource = item.thumbnailResource,
            let uiImage = UIImage(named: resource, in: .module, compatibleWith: nil)
        {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let uiImage = UIImage(contentsOfFile: item.imagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle().fill(Color(.systemGray5))
        }
    }

    @ViewBuilder
    private func deleteOverlay(_ item: VideoBackgroundItem) -> some View {
        Button {
            viewModel.deleteBackground(item)
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .black.opacity(0.6))
                .padding(4)
        }
        .accessibilityLabel(String(localized: "Delete background", bundle: .module))
    }

    @ViewBuilder
    private var addImageTile: some View {
        Group {
            if viewModel.remainingSlots > 0 {
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: viewModel.remainingSlots,
                    matching: .images
                ) {
                    addImageTileLabel
                }
                .onChange(of: selectedPhotos) { newItems in
                    viewModel.addBackgrounds(newItems)
                    selectedPhotos = []
                }
            } else {
                Button {
                    viewModel.showMaxImagesError()
                } label: {
                    addImageTileLabel
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel(String(localized: "Add image", bundle: .module))
        .alert(
            String(localized: "Limit reached", bundle: .module),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK", bundle: .module), role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }

    private var addImageTileLabel: some View {
        VStack {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [6]))
        )
    }
}
