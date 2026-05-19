//
//  Created by Vonage on 14/4/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERAChat

@Suite("ChatBadgeButton UI Tests")
@MainActor
struct ChatBadgeButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "ChatBadgeButton"

    // MARK: - Badge State Tests

    @Test(
        "ChatBadgeButton - Badge States",
        arguments: [
            ("no-badge", 0),
            ("low-count", 3),
            ("high-count", 25),
            ("overflow", 100),
        ])
    func badgeStates(variant: String, unreadCount: Int) throws {
        let sut = makeSUT(unreadMessagesCount: unreadCount)

        snapshot(sut, named: variant)
    }

    // MARK: - Color Scheme Tests

    @Test(
        "ChatBadgeButton - Color Schemes",
        arguments: [
            ("Dark", ColorScheme.dark)
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(unreadMessagesCount: 5)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        unreadMessagesCount: Int = 0
    ) -> ChatBadgeButton {
        ChatBadgeButton(
            unreadMessagesCount: unreadMessagesCount,
            onShowChat: {}
        )
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
