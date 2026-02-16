//
//  Created by Vonage on 16/2/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAReactions

@Suite("FloatingEmojiView UI Tests")
@MainActor
struct FloatingEmojiViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "FloatingEmojiView"

    // MARK: - Participant Name Variants

    @Test(
        "Renders correct layout for each participant variant",
        arguments: [
            ("RemoteUser", "🎉", "Alice", false),
            ("LocalUser", "👍", "Me", true),
            ("LongName", "❤️", "Alexander Hamilton", false),
            ("EmptyName", "🔥", "", false),
        ])
    func participantVariants(
        caseName: String,
        emoji: String,
        name: String,
        isMe: Bool
    ) {
        let sut = makeSUT(emoji: emoji, participantName: name, isMe: isMe)

        snapshot(sut, named: "Variant_\(caseName)")
    }

    // MARK: - Color Schemes

    @Test(
        "Adapts appearance to light and dark color schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) {
        let sut = makeSUT(emoji: "🎉", participantName: "Alice", isMe: false)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: "ColorScheme_\(schemeName)")
    }

    @Test(
        "Local user label adapts to light and dark color schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func localUserColorSchemes(schemeName: String, scheme: ColorScheme) {
        let sut = makeSUT(emoji: "👍", participantName: "Me", isMe: true)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: "LocalUser_\(schemeName)")
    }

    // MARK: - Accessibility

    @Test(
        "Scales correctly across dynamic type sizes",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall),
            ("DefaultText", ContentSizeCategory.medium),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge),
        ])
    func accessibilitySizes(textName: String, textSize: ContentSizeCategory) {
        let sut = makeSUT(emoji: "🎉", participantName: "Alice", isMe: false)
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: "Accessibility_\(textName)")
    }

    // MARK: - Empty Name

    @Test("Hides name label when participantName is empty and isMe is false")
    func emptyNameHidesLabel() {
        let sut = makeSUT(emoji: "🔥", participantName: "", isMe: false)

        snapshot(sut, named: "EmptyName_NoLabel")
    }

    @Test("Shows localized You label when participantName is empty but isMe is true")
    func emptyNameShowsYouForLocalUser() {
        let sut = makeSUT(emoji: "👍", participantName: "", isMe: true)

        snapshot(sut, named: "EmptyName_IsMe")
    }

    // MARK: - All Variants Comparison

    @Test("Renders all participant variants side by side")
    func allVariantsSideBySide() {
        let sut = HStack(spacing: 25) {
            FloatingEmojiView(emoji: "🎉", participantName: "Alice", isMe: false)
            FloatingEmojiView(emoji: "👍", participantName: "Me", isMe: true)
            FloatingEmojiView(emoji: "❤️", participantName: "Charlie", isMe: false)
            FloatingEmojiView(emoji: "🔥", participantName: "", isMe: false)
            FloatingEmojiView(emoji: "🔥", participantName: "Alexander Hamilton", isMe: false)
        }
        .padding()
        .background(Color.gray.opacity(0.3))

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone8Plus)),
            named: "AllVariants",
            record: isRecording,
            testName: "\(snapshotPrefix)_AllVariants"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        emoji: String,
        participantName: String,
        isMe: Bool
    ) -> some View {
        ZStack {
            Color.gray.opacity(0.3)
                .ignoresSafeArea()

            FloatingEmojiView(emoji: emoji, participantName: participantName, isMe: isMe)
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
            as: .image(precision: 0.99, layout: .fixed(width: 160, height: 120)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
