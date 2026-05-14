//
//  Created by Vonage on 15/4/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAChat

@Suite("ChatPanelMessages UI Tests")
@MainActor
struct ChatPanelMessagesSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "ChatPanelMessages"

    // MARK: - Content State Tests

    @Test(
        "ChatPanelMessages - Content States",
        arguments: [
            ("Empty", [UIChatMessage]()),
            ("Populated", UIChatMessage.sampleMessages),
        ])
    func contentStates(variant: String, messages: [UIChatMessage]) throws {
        let sut = makeSUT(messages: messages)

        snapshot(sut, named: "Content_\(variant)")
    }

    // MARK: - Color Scheme Tests

    @Test(
        "ChatPanelMessages - Color Schemes",
        arguments: [
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(messages: UIChatMessage.sampleMessages)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    // MARK: - Test Helpers

    private func makeSUT(messages: [UIChatMessage]) -> ChatPanelMessages {
        ChatPanelMessages(messages: messages)
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
