//
//  Created by Vonage on 12/2/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAReactions

@Suite("EmojiItemView UI Tests")
@MainActor
struct EmojiItemViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "EmojiItemView"

    // MARK: - Default Emojis Tests

    @Test(
        "EmojiItemView - Default Emojis",
        arguments: [
            ("ThumbsUp", UIEmojiReaction(emoji: "👍", name: "thumbs up")),
            ("Heart", UIEmojiReaction(emoji: "❤️", name: "heart")),
            ("Fire", UIEmojiReaction(emoji: "🔥", name: "fire")),
            ("Laughing", UIEmojiReaction(emoji: "😂", name: "laughing")),
            ("Clap", UIEmojiReaction(emoji: "👏", name: "clap")),
            ("Party", UIEmojiReaction(emoji: "🎉", name: "party")),
        ])
    func defaultEmojis(emojiName: String, emoji: UIEmojiReaction) throws {
        let sut = makeSUT(emoji: emoji)

        snapshot(sut, named: "Emoji_\(emojiName)")
    }

    // MARK: - Highlight State Tests

    @Test(
        "EmojiItemView - Highlight States",
        arguments: [
            ("Normal", false),
            ("Highlighted", true),
        ])
    func highlightStates(stateName: String, isHighlighted: Bool) throws {
        let sut = makeSUT(
            emoji: UIEmojiReaction(emoji: "👍", name: "thumbs up"),
            isHighlighted: isHighlighted
        )

        snapshot(sut, named: "Highlight_\(stateName)")
    }

    // MARK: - Color Schemes

    @Test(
        "EmojiItemView - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(emoji: UIEmojiReaction(emoji: "👍", name: "thumbs up"))
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: "ColorScheme_\(schemeName)")
    }

    @Test(
        "EmojiItemView - Highlighted Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func highlightedColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(
            emoji: UIEmojiReaction(emoji: "👍", name: "thumbs up"),
            isHighlighted: true
        )
        .environment(\.colorScheme, scheme)

        snapshot(sut, named: "Highlighted_\(schemeName)")
    }

    // MARK: - Accessibility

    @Test(
        "EmojiItemView - Accessibility Sizes",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall),
            ("DefaultText", ContentSizeCategory.medium),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge),
        ])
    func accessibilitySizes(textName: String, textSize: ContentSizeCategory) throws {
        let sut = makeSUT(emoji: UIEmojiReaction(emoji: "👍", name: "thumbs up"))
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: "Accessibility_\(textName)")
    }

    // MARK: - Grid Layout

    @Test("EmojiItemView - Grid Row")
    func gridRow() throws {
        let sut = HStack(spacing: 12) {
            EmojiItemView(emoji: UIEmojiReaction(emoji: "👍", name: "thumbs up"))
            EmojiItemView(emoji: UIEmojiReaction(emoji: "❤️", name: "heart"))
            EmojiItemView(emoji: UIEmojiReaction(emoji: "🔥", name: "fire"))
            EmojiItemView(emoji: UIEmojiReaction(emoji: "😂", name: "laughing"))
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .sizeThatFits),
            named: "GridRow",
            record: isRecording,
            testName: "\(snapshotPrefix)_GridRow"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        emoji: UIEmojiReaction,
        isHighlighted: Bool = false
    ) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            EmojiItemView(emoji: emoji, isHighlighted: isHighlighted)
        }
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: 60, height: 60)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
