//
//  Created by Vonage on 9/2/26.
//

import SwiftUI

/// Constants for EmojItemView layout
public enum EmojiItemConstants {
    /// Size of emoji cell (width and height)
    public static let cellSize: CGFloat = 36

    /// Font size for the emoji
    public static let fontSize: CGFloat = 28

    /// Highlight animation duration in seconds
    public static let highlightDuration: Double = 0.15

    /// Highlight background opacity
    public static let highlightOpacity: Double = 0.4

    /// Highlight corner radius
    public static let highlightCornerRadius: CGFloat = 8
}

/// A single emoji cell displayed within the grid
///
/// Displays an emoji character centered in a fixed-size container.
/// Designed for accessibility with a minimum touch target of 36x36 points.
///
/// ## Usage
/// ```swift
/// EmojiCell(emoji: EmojiItem(emoji: "👍", name: "thumbs up"))
///     .onTapGesture { /* handle tap */ }
/// ```
///
/// ## Accessibility
/// The cell uses the emoji's `name` property as its accessibility label,
/// allowing VoiceOver to announce the emoji's meaning.
struct EmojiItemView: View {
    /// The emoji item to display
    let emoji: EmojiItem

    /// Whether the cell is currently highlighted
    var isHighlighted: Bool = false

    /// Duration of the highlight animation in seconds
    var highlightDuration: Double = EmojiItemConstants.highlightDuration

    var body: some View {
        Text(emoji.emoji)
            .font(.system(size: EmojiItemConstants.fontSize))
            .frame(width: EmojiItemConstants.cellSize, height: EmojiItemConstants.cellSize)
            .background(
                RoundedRectangle(cornerRadius: EmojiItemConstants.highlightCornerRadius)
                    .fill(Color.white.opacity(isHighlighted ? EmojiItemConstants.highlightOpacity : 0))
            )
            .accessibilityLabel(emoji.name)
            .animation(.easeInOut(duration: highlightDuration), value: isHighlighted)
    }
}

// MARK: - Previews

#Preview("Emoji Cell") {
    HStack(spacing: EmojiPickerConstants.gridSpacing) {
        EmojiItemView(emoji: EmojiItem(emoji: "👍", name: "thumbs up"))
        EmojiItemView(emoji: EmojiItem(emoji: "❤️", name: "heart"))
        EmojiItemView(emoji: EmojiItem(emoji: "🔥", name: "fire"))
        EmojiItemView(emoji: EmojiItem(emoji: "😂", name: "laughing"))
    }
    .padding()
    .background(Color.black.opacity(EmojiPickerConstants.backgroundOpacity))
    .cornerRadius(EmojiPickerConstants.cornerRadius)
}
