//
//  Created by Vonage on 23/06/2026.
//

import SwiftUI
import VERACommonUI

private enum ManualCodecReorderConstants {
    static let rowHeight: CGFloat = 44
    static let rowVerticalPadding: CGFloat = 4
    static let rowSpacing: CGFloat = 0
    static let handleHitArea: CGFloat = 28
    static let dragMinimumDistance: CGFloat = 4
    static let rowStep: CGFloat = rowHeight + (rowVerticalPadding * 2)
    static let moveThreshold: CGFloat = rowStep * 0.7
    static let activeScale: CGFloat = 1.02
    static let activeShadowRadius: CGFloat = 10
    static let inactiveShadowRadius: CGFloat = 0
    static let reorderAnimation = Animation.interactiveSpring(response: 0.24, dampingFraction: 0.82)
    static let releaseAnimation = Animation.spring(response: 0.22, dampingFraction: 0.88)
}

struct ManualCodecReorderView: View {

    let orderedCodecs: [SettingsVideoCodec]
    let priorityLabel: (SettingsVideoCodec) -> String
    let onMove: (IndexSet, Int) -> Void

    @State private var draggedCodec: SettingsVideoCodec?
    @State private var dragBaselineTranslation: CGFloat = 0
    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        VStack(spacing: ManualCodecReorderConstants.rowSpacing) {
            ForEach(Array(orderedCodecs.enumerated()), id: \.element.id) { index, codec in
                codecRow(codec)

                if index < orderedCodecs.count - 1 {
                    SettingsDivider()
                }
            }
        }
    }

    private func codecRow(_ codec: SettingsVideoCodec) -> some View {
        let isDragged = draggedCodec == codec

        return HStack(spacing: 12) {
            reorderHandle(for: codec)

            Text(codec.displayName)

            Spacer()

            Text(priorityLabel(codec))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: ManualCodecReorderConstants.rowHeight)
        .padding(.vertical, ManualCodecReorderConstants.rowVerticalPadding)
        .contentShape(Rectangle())
        .background(isDragged ? Color.accentColor.opacity(0.10) : .clear)
        .offset(y: isDragged ? dragTranslation : 0)
        .scaleEffect(isDragged ? ManualCodecReorderConstants.activeScale : 1)
        .shadow(
            color: .black.opacity(isDragged ? 0.12 : 0),
            radius: isDragged
                ? ManualCodecReorderConstants.activeShadowRadius
                : ManualCodecReorderConstants.inactiveShadowRadius,
            y: isDragged ? 4 : 0
        )
        .zIndex(isDragged ? 1 : 0)
        .animation(ManualCodecReorderConstants.reorderAnimation, value: orderedCodecs)
        .animation(ManualCodecReorderConstants.reorderAnimation, value: dragTranslation)
        .animation(ManualCodecReorderConstants.releaseAnimation, value: draggedCodec)
    }

    private func reorderHandle(for codec: SettingsVideoCodec) -> some View {
        VERACommonUIAsset.Images.menuSolid.swiftUIImage
            .foregroundStyle(.secondary)
            .frame(
                width: ManualCodecReorderConstants.handleHitArea,
                height: ManualCodecReorderConstants.handleHitArea
            )
            .contentShape(Rectangle())
            .gesture(dragGesture(for: codec))
    }

    private func dragGesture(for codec: SettingsVideoCodec) -> some Gesture {
        DragGesture(minimumDistance: ManualCodecReorderConstants.dragMinimumDistance)
            .onChanged { value in
                if draggedCodec == nil {
                    withAnimation(ManualCodecReorderConstants.releaseAnimation) {
                        draggedCodec = codec
                        dragBaselineTranslation = 0
                    }
                }

                reorderDraggedCodec(codec, translation: value.translation.height)
            }
            .onEnded { _ in
                withAnimation(ManualCodecReorderConstants.releaseAnimation) {
                    dragTranslation = 0
                    dragBaselineTranslation = 0
                    draggedCodec = nil
                }
            }
    }

    private func reorderDraggedCodec(_ codec: SettingsVideoCodec, translation: CGFloat) {
        guard draggedCodec == codec else { return }
        guard let currentIndex = orderedCodecs.firstIndex(of: codec) else { return }

        let relativeTranslation = translation - dragBaselineTranslation
        dragTranslation = relativeTranslation

        if relativeTranslation > ManualCodecReorderConstants.moveThreshold,
            currentIndex < orderedCodecs.count - 1
        {
            withAnimation(ManualCodecReorderConstants.reorderAnimation) {
                onMove(IndexSet(integer: currentIndex), currentIndex + 2)
                dragBaselineTranslation += ManualCodecReorderConstants.rowStep
                dragTranslation = translation - dragBaselineTranslation
            }
        } else if relativeTranslation < -ManualCodecReorderConstants.moveThreshold,
            currentIndex > 0
        {
            withAnimation(ManualCodecReorderConstants.reorderAnimation) {
                onMove(IndexSet(integer: currentIndex), currentIndex - 1)
                dragBaselineTranslation -= ManualCodecReorderConstants.rowStep
                dragTranslation = translation - dragBaselineTranslation
            }
        }
    }
}

#if DEBUG
    #Preview("Manual Codec Reorder") {
        Form {
            ManualCodecReorderView(
                orderedCodecs: [.vp9, .vp8, .h264],
                priorityLabel: { codec in
                    switch codec {
                    case .vp9: "1st".localized
                    case .vp8: "2nd".localized
                    case .h264: "3rd".localized
                    }
                },
                onMove: { _, _ in }
            )
        }
        .preferredColorScheme(.dark)
    }
#endif
