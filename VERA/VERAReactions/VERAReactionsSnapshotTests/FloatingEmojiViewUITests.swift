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
