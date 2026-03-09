//
//  Created by Vonage on 14/2/26.
//

import SwiftUI
import VERACommonUI

/// Constants for ``FloatingEmojiView``.
private enum FloatingEmojiConstants {
    /// Maximum width for the name label before truncation (points).
    static let maxDisplayNameWidth: CGFloat = 80
    /// Font size for the emoji character.
    static let fontSize: CGFloat = 40
}

/// A simple view that displays an emoji character and, optionally, the
/// sender's name in a label beneath it.
///
/// When `isMe` is `true` the label shows a localized "You" string;
/// when `participantName` is empty the label is hidden entirely.
///
/// This view is intentionally stateless and contains no animation logic.
/// Use the ``balloonAnimation(containerHeight:)`` modifier to
/// apply the balloon-rise effect.
///
/// ## Example
///
/// ```swift
/// // Static (default)
/// FloatingEmojiView(emoji: "🎉", participantName: "Alice", isMe: false)
///
/// // With balloon animation
/// FloatingEmojiView(emoji: "🎉", participantName: "Alice", isMe: false)
///     .balloonAnimation(containerHeight: geometry.size.height)
/// ```
///
/// - SeeAlso: ``FloatingEmojisOverlayView``
struct FloatingEmojiView: View {

    // MARK: - Properties

    /// The emoji character to render.
    let emoji: String

    /// The display name of the participant who sent this reaction.
    ///
    /// When empty and `isMe` is `false`, the name label is hidden.
    let participantName: String

    /// Indicates whether the local user sent this reaction.
    ///
    /// When `true`, the name label displays a localized "You" string
    /// instead of ``participantName``.
    let isMe: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: FloatingEmojiConstants.fontSize))
            if !displayName.isEmpty {
                Text(displayName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: FloatingEmojiConstants.maxDisplayNameWidth)
                    .fixedSize(horizontal: true, vertical: false)
                    .font(.caption2)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.onAccent.swiftUIColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(VERACommonUIAsset.SemanticColors.accent.swiftUIColor)
                    .cornerRadius(8)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Private

    /// The resolved name to display beneath the emoji.
    ///
    /// Returns a localized "You" when ``isMe`` is `true`,
    /// otherwise returns ``participantName`` as-is.
    private var displayName: String {
        isMe ? String(localized: "You", bundle: .veraReactions) : participantName
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        VStack(spacing: 16) {
            FloatingEmojiView(emoji: "🎉", participantName: "Alice", isMe: false)
            FloatingEmojiView(emoji: "👍", participantName: "", isMe: true)
            FloatingEmojiView(emoji: "❤️", participantName: "Alexander Hamilton", isMe: false)
            FloatingEmojiView(emoji: "❤️", participantName: "Alexander", isMe: false)
            FloatingEmojiView(emoji: "❤️", participantName: "", isMe: false)
        }
    }
#endif
