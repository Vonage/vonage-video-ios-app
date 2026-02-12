//
//  Created by Vonage on 9/2/26.
//

import Combine
import SwiftUI
import VERACommonUI

/// Constants for EmojiPickerView layout and appearance
public enum EmojiPickerConstants {
    /// Number of columns in the grid
    public static let columnCount: Int = 4

    /// Spacing between grid items
    public static let gridSpacing: CGFloat = 8

    /// Padding around the grid content
    public static let contentPadding: CGFloat = 12

    /// Corner radius of the grid background
    public static let cornerRadius: CGFloat = 12

    /// Background opacity
    public static let backgroundOpacity: Double = 0.8
}

/// A flexible grid view for displaying emoji reactions
///
/// Displays emojis in a 4-column grid layout with dynamic height.
/// The grid automatically adjusts its width to fit exactly 4 columns,
/// preventing it from expanding to fill the entire screen width on larger devices like iPad.
///
/// ## Features
/// - Fixed 4-column layout
/// - Dynamic height based on content
/// - Semi-transparent black background
/// - Accessible with VoiceOver support
///
/// ## Usage
/// ```swift
/// EmojiPickerView(
///     emojis: UIEmojiReaction.defaultEmojis,
///     onEmojiSelected: { emoji in
///         print("Selected: \(emoji.emoji)")
///     }
/// )
/// ```
///
/// ## Layout
/// The grid uses `fixedSize(horizontal: true, vertical: false)` to wrap
/// its width to the content, making it suitable for popovers or overlays.
///
/// - Note: Each cell is 36x36 points with 8pt spacing between items.
public struct EmojiPickerView: View {
    /// The array of emojis to display in the grid
    public let emojis: [UIEmojiReaction]

    /// Whether to show highlight animation on tap
    public let showsHighlight: Bool

    /// Duration of the highlight animation in seconds
    public let highlightDuration: Double

    /// Callback triggered when an emoji is selected
    public let onEmojiSelected: (UIEmojiReaction) -> Void

    /// Creates a new emoji grid view
    /// - Parameters:
    ///   - emojis: The emojis to display
    ///   - showsHighlight: Whether to show highlight animation on tap (default: true)
    ///   - highlightDuration: Duration of highlight animation in seconds (default: 0.15)
    ///   - onEmojiSelected: Callback when an emoji is tapped
    public init(
        emojis: [UIEmojiReaction],
        showsHighlight: Bool = true,
        highlightDuration: Double = EmojiItemConstants.highlightDuration,
        onEmojiSelected: @escaping (UIEmojiReaction) -> Void
    ) {
        self.emojis = emojis
        self.showsHighlight = showsHighlight
        self.highlightDuration = highlightDuration
        self.onEmojiSelected = onEmojiSelected
    }

    public var body: some View {
        EmojiPickerViewContent(
            emojis: emojis,
            showsHighlight: showsHighlight,
            highlightDuration: highlightDuration,
            onEmojiSelected: onEmojiSelected
        )
        .padding(EmojiPickerConstants.contentPadding)
        .background(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(EmojiPickerConstants.backgroundOpacity))
        .cornerRadius(EmojiPickerConstants.cornerRadius)
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Internal view that handles the emoji grid and highlight state
private struct EmojiPickerViewContent: View {
    let emojis: [UIEmojiReaction]
    let showsHighlight: Bool
    let highlightDuration: Double
    let onEmojiSelected: (UIEmojiReaction) -> Void

    @State private var highlightedEmojiId: String?
    @State private var highlightCancellable: AnyCancellable?

    private let columns = Array(
        repeating: GridItem(.fixed(EmojiItemConstants.cellSize), spacing: EmojiPickerConstants.gridSpacing),
        count: EmojiPickerConstants.columnCount
    )

    /// Delay before clearing the highlight (animation in + out)
    private var highlightClearDelay: Double {
        highlightDuration * 2
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: EmojiPickerConstants.gridSpacing) {
            ForEach(emojis) { emoji in
                EmojiItemView(
                    emoji: emoji,
                    isHighlighted: showsHighlight && highlightedEmojiId == emoji.id.uuidString,
                    highlightDuration: highlightDuration
                )
                .onTapGesture {
                    handleEmojiTap(emoji)
                }
            }
        }
    }

    private func handleEmojiTap(_ emoji: UIEmojiReaction) {
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

#Preview("Dynamic Height") {
    EmojiPickerView(
        emojis: UIEmojiReaction.defaultEmojis,
        onEmojiSelected: { emoji in
            print("Selected: \(emoji.emoji)")
        }
    ).padding()
}

#Preview("Few Emojis") {
    EmojiPickerView(
        emojis: Array(UIEmojiReaction.defaultEmojis.prefix(5)),
        onEmojiSelected: { _ in }
    )
    .padding()
}

#Preview("Single Row") {
    EmojiPickerView(
        emojis: Array(UIEmojiReaction.defaultEmojis.prefix(4)),
        onEmojiSelected: { _ in }
    )
    .frame(width: 250)
    .padding()
}
