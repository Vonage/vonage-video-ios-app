//
//  Created by Vonage on 19/06/2026.
//

import Combine
import SwiftUI
import VERACommonUI

private enum EmojiHorizontalPickerConstants {
    static let verticalPadding: CGFloat = 8
    static let horizontalPadding: CGFloat = 12
    static let scrollAffordanceWidth: CGFloat = 32
    static let scrollAffordanceTolerance: CGFloat = 1
    static let scrollCoordinateSpace = "emoji-horizontal-picker-scroll"
}

/// A horizontal picker for sending emoji reactions from compact surfaces.
///
/// `EmojiHorizontalPickerView` renders the provided reactions in a single
/// horizontally scrollable row. It is intended for compact UI surfaces, such as
/// overflow sheets, where the full grid picker would take too much vertical
/// space.
///
/// The picker reuses `EmojiItemView` for each cell, so sizing, spacing,
/// accessibility labels, and highlight styling stay aligned with the standard
/// emoji picker.
///
/// When the row has more content than the visible area, the picker shows edge
/// fades to indicate that more reactions are available by scrolling.
///
/// ## Usage
/// ```swift
/// EmojiHorizontalPickerView(emojis: UIEmojiReaction.defaultEmojis) { emoji in
///     sendReaction(emoji)
/// }
/// ```
public struct EmojiHorizontalPickerView: View {
    @Environment(\.meetingRoomTheme) private var theme

    private let emojis: [UIEmojiReaction]
    private let showsHighlight: Bool
    private let highlightDuration: Double
    private let highlightColor: Color
    private let showsScrollAffordance: Bool
    private let onEmojiSelected: (UIEmojiReaction) -> Void

    @State private var visibleWidth: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0

    /// Creates a horizontal emoji picker.
    /// - Parameters:
    ///   - emojis: The emoji reactions to render in the horizontal row.
    ///   - showsHighlight: Whether to show a temporary highlight when an emoji is tapped.
    ///   - highlightDuration: The duration, in seconds, of the highlight animation.
    ///   - highlightColor: The color used for the temporary highlight.
    ///   - showsScrollAffordance: Whether to show edge fades when more emojis are hidden by scrolling.
    ///   - onEmojiSelected: A callback invoked when the user selects an emoji.
    public init(
        emojis: [UIEmojiReaction],
        showsHighlight: Bool = true,
        highlightDuration: Double = EmojiItemConstants.highlightDuration,
        highlightColor: Color = .white,
        showsScrollAffordance: Bool = true,
        onEmojiSelected: @escaping (UIEmojiReaction) -> Void
    ) {
        self.emojis = emojis
        self.showsHighlight = showsHighlight
        self.highlightDuration = highlightDuration
        self.highlightColor = highlightColor
        self.showsScrollAffordance = showsScrollAffordance
        self.onEmojiSelected = onEmojiSelected
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            EmojiHorizontalPickerContent(
                emojis: emojis,
                showsHighlight: showsHighlight,
                highlightDuration: highlightDuration,
                highlightColor: highlightColor,
                onEmojiSelected: onEmojiSelected
            )
            .fixedSize(horizontal: true, vertical: false)
            .readEmojiHorizontalPickerContentWidth()
            .readEmojiHorizontalPickerScrollOffset(in: EmojiHorizontalPickerConstants.scrollCoordinateSpace)
        }
        .coordinateSpace(name: EmojiHorizontalPickerConstants.scrollCoordinateSpace)
        .readEmojiHorizontalPickerVisibleWidth()
        .onPreferenceChange(EmojiHorizontalPickerVisibleWidthKey.self) { visibleWidth = $0 }
        .onPreferenceChange(EmojiHorizontalPickerContentWidthKey.self) { contentWidth = $0 }
        .onPreferenceChange(EmojiHorizontalPickerScrollOffsetKey.self) { scrollOffset = max(0, -$0) }
        .horizontalScrollAffordanceMask(
            isEnabled: showsScrollAffordance,
            visibleWidth: visibleWidth,
            contentWidth: contentWidth,
            scrollOffset: scrollOffset,
            fadeWidth: EmojiHorizontalPickerConstants.scrollAffordanceWidth,
            tolerance: EmojiHorizontalPickerConstants.scrollAffordanceTolerance
        )
        .padding(.horizontal, EmojiHorizontalPickerConstants.horizontalPadding)
        .padding(.vertical, EmojiHorizontalPickerConstants.verticalPadding)
    }
}

struct EmojiHorizontalPickerContent: View {
    let emojis: [UIEmojiReaction]
    let showsHighlight: Bool
    let highlightDuration: Double
    let highlightColor: Color
    let onEmojiSelected: (UIEmojiReaction) -> Void

    @State private var highlightedEmojiId: String?
    @State private var highlightCancellable: AnyCancellable?

    private var highlightClearDelay: Double {
        highlightDuration * 2
    }

    var body: some View {
        HStack(spacing: EmojiPickerConstants.gridSpacing) {
            ForEach(emojis) { emoji in
                EmojiItemView(
                    emoji: emoji,
                    isHighlighted: isHighlighted(emoji),
                    highlightDuration: highlightDuration,
                    highlightColor: highlightColor
                )
                .onTapGesture {
                    handleEmojiTap(emoji)
                }
            }
        }
    }

    private func isHighlighted(_ emoji: UIEmojiReaction) -> Bool {
        showsHighlight && highlightedEmojiId == emoji.id.uuidString
    }

    func handleEmojiTap(_ emoji: UIEmojiReaction) {
        if showsHighlight {
            highlightedEmojiId = emoji.id.uuidString
        }
        onEmojiSelected(emoji)

        highlightCancellable?.cancel()
        highlightCancellable = Just(())
            .delay(for: .seconds(highlightClearDelay), scheduler: RunLoop.main)
            .sink { _ in
                if highlightedEmojiId == emoji.id.uuidString {
                    highlightedEmojiId = nil
                }
            }
    }
}

#if DEBUG
    #Preview("Default") {
        EmojiHorizontalPickerView(emojis: UIEmojiReaction.defaultEmojis) { _ in }
            .padding()
            .background(Color.gray.opacity(0.12))
    }

    #Preview("Few Emojis") {
        EmojiHorizontalPickerView(emojis: Array(UIEmojiReaction.defaultEmojis.prefix(3))) { _ in }
            .padding()
            .background(Color.gray.opacity(0.12))
    }

    #Preview("Narrow Width") {
        EmojiHorizontalPickerView(emojis: UIEmojiReaction.defaultEmojis) { _ in }
            .frame(width: 240)
            .padding()
            .background(Color.gray.opacity(0.12))
    }

    #Preview("Dark") {
        EmojiHorizontalPickerView(emojis: UIEmojiReaction.defaultEmojis) { _ in }
            .padding()
            .background(Color.gray.opacity(0.12))
            .preferredColorScheme(.dark)
    }

    #Preview("Custom Highlight") {
        EmojiHorizontalPickerView(
            emojis: UIEmojiReaction.defaultEmojis,
            highlightColor: .black
        ) { _ in }
        .padding()
        .background(Color.gray.opacity(0.12))
    }
#endif
