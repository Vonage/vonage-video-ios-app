//
//  EmojiGridView.swift
//  VERAReactions
//

import Combine
import SwiftUI

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
    public static let backgroundOpacity: Double = 0.75
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
/// EmojiGridView(
///     emojis: EmojiItem.samples,
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
    public let emojis: [EmojiItem]

    /// Callback triggered when an emoji is selected
    public let onEmojiSelected: (EmojiItem) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: EmojiPickerConstants.gridSpacing),
        count: EmojiPickerConstants.columnCount
    )

    /// Creates a new emoji grid view
    /// - Parameters:
    ///   - emojis: The emojis to display
    ///   - onEmojiSelected: Callback when an emoji is tapped
    public init(
        emojis: [EmojiItem],
        onEmojiSelected: @escaping (EmojiItem) -> Void
    ) {
        self.emojis = emojis
        self.onEmojiSelected = onEmojiSelected
    }

    /// Creates a default emoji picker view with the standard set of emojis
    /// - Parameter onEmojiSelected: Callback when an emoji is tapped
    /// - Returns: An EmojiPickerView configured with default emojis
    public static func defaultPickerView(
        onEmojiSelected: @escaping (EmojiItem) -> Void
    ) -> EmojiPickerView {
        EmojiPickerViewFactory.makeDefault(onEmojiSelected: onEmojiSelected)
    }

    public var body: some View {
        EmojiPickerViewContent(emojis: emojis, onEmojiSelected: onEmojiSelected)
            .padding(EmojiPickerConstants.contentPadding)
            .background(Color.black.opacity(EmojiPickerConstants.backgroundOpacity))
            .cornerRadius(EmojiPickerConstants.cornerRadius)
            .fixedSize(horizontal: true, vertical: false)
    }
}

/// Internal view that handles the emoji grid and highlight state
private struct EmojiPickerViewContent: View {
    let emojis: [EmojiItem]
    let onEmojiSelected: (EmojiItem) -> Void

    @State private var highlightedEmojiId: String?
    @State private var highlightCancellable: AnyCancellable?

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: EmojiPickerConstants.gridSpacing),
        count: EmojiPickerConstants.columnCount
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: EmojiPickerConstants.gridSpacing) {
            ForEach(emojis) { emoji in
                EmojItemView(emoji: emoji, isHighlighted: highlightedEmojiId == emoji.id.uuidString)
                    .onTapGesture {
                        handleEmojiTap(emoji)
                    }
            }
        }
    }

    private func handleEmojiTap(_ emoji: EmojiItem) {
        highlightedEmojiId = emoji.id.uuidString
        onEmojiSelected(emoji)

        highlightCancellable?.cancel()
        highlightCancellable = Just(())
            .delay(for: .seconds(EmojiItemConstants.highlightDuration * 2), scheduler: RunLoop.main)
            .sink { _ in
                if highlightedEmojiId == emoji.id.uuidString {
                    highlightedEmojiId = nil
                }
            }
    }
}

#Preview("Dynamic Height") {
    EmojiPickerView(
        emojis: EmojiItem.defaultEmojis,
        onEmojiSelected: { emoji in
            print("Selected: \(emoji.emoji)")
        }
    ).padding()
}

#Preview("Few Emojis") {
    EmojiPickerView(
        emojis: Array(EmojiItem.defaultEmojis.prefix(5)),
        onEmojiSelected: { _ in }
    )
    .padding()
}

#Preview("Single Row") {
    EmojiPickerView(
        emojis: Array(EmojiItem.defaultEmojis.prefix(4)),
        onEmojiSelected: { _ in }
    )
    .frame(width: 250)
    .padding()
}

#Preview("Default Picker") {
    EmojiPickerView.defaultPickerView { emoji in
        print("Selected: \(emoji.emoji)")
    }
    .padding()
}
