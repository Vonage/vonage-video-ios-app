//
//  Created by Vonage on 19/06/2026.
//

import Combine
import SwiftUI
import VERACommonUI

private enum EmojiHorizontalPickerConstants {
    static let emojiFontSize: CGFloat = 32
    static let verticalPadding: CGFloat = 8
    static let horizontalPadding: CGFloat = 12
}

/// A horizontal picker for sending emoji reactions from compact surfaces.
public struct EmojiHorizontalPickerView: View {
    private let emojis: [UIEmojiReaction]
    private let showsHighlight: Bool
    private let highlightDuration: Double
    private let onEmojiSelected: (UIEmojiReaction) -> Void

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
        ScrollView(.horizontal, showsIndicators: false) {
            EmojiHorizontalPickerContent(
                emojis: emojis,
                showsHighlight: showsHighlight,
                highlightDuration: highlightDuration,
                onEmojiSelected: onEmojiSelected
            )
        }
        .padding(.horizontal, EmojiHorizontalPickerConstants.horizontalPadding)
        .padding(.vertical, EmojiHorizontalPickerConstants.verticalPadding)
    }
}

private struct EmojiHorizontalPickerContent: View {
    let emojis: [UIEmojiReaction]
    let showsHighlight: Bool
    let highlightDuration: Double
    let onEmojiSelected: (UIEmojiReaction) -> Void

    @State private var highlightedEmojiId: String?
    @State private var highlightCancellable: AnyCancellable?

    private var highlightClearDelay: Double {
        highlightDuration * 2
    }

    var body: some View {
        HStack(spacing: EmojiPickerConstants.gridSpacing) {
            ForEach(emojis) { emoji in
                Text(emoji.emoji)
                    .font(.system(size: EmojiHorizontalPickerConstants.emojiFontSize))
                    .frame(width: EmojiItemConstants.cellSize, height: EmojiItemConstants.cellSize)
                    .background(
                        RoundedRectangle(cornerRadius: EmojiItemConstants.highlightCornerRadius)
                            .fill(Color.white.opacity(isHighlighted(emoji) ? EmojiItemConstants.highlightOpacity : 0))
                    )
                    .accessibilityLabel(emoji.name)
                    .animation(.easeInOut(duration: highlightDuration), value: highlightedEmojiId)
                    .onTapGesture {
                        handleEmojiTap(emoji)
                    }
            }
        }
    }

    private func isHighlighted(_ emoji: UIEmojiReaction) -> Bool {
        showsHighlight && highlightedEmojiId == emoji.id.uuidString
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

#if DEBUG
    #Preview {
        EmojiHorizontalPickerView(emojis: UIEmojiReaction.defaultEmojis) { emoji in
            print("Selected: \(emoji.emoji)")
        }
        .padding()
    }
#endif
