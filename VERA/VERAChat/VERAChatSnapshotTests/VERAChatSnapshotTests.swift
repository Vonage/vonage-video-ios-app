//
//  Created by Vonage on 17/10/25.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERAChat
import VERAChatAppTestHelpers

@Suite("Chat panel UI Tests")
@MainActor
struct VERAChatSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "Chat"

    // MARK: - Core UI Tests

    @Test(
        "Chat View - Basic Layout",
        arguments: [
            ("without-messages", []),
            ("with-messages", UIChatMessage.sampleMessages),
        ])
    func basicLayout(variant: String, messages: [UIChatMessage]) throws {
        let sut = makeSUT(messages: messages)

        snapshot(sut, named: "Default-\(variant)")
    }

    @Test(
        "GoodBye View - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13, []),
            ("iPad", ViewImageConfig.iPadPro12_9, []),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape), []),
            ("iPhone-with-messages", ViewImageConfig.iPhone13, UIChatMessage.sampleMessages),
            ("iPad-with-messages", ViewImageConfig.iPadPro12_9, UIChatMessage.sampleMessages),
            ("iPhoneLandscape-with-messages", ViewImageConfig.iPhone13(.landscape), UIChatMessage.sampleMessages),
        ])
    func sizeClasses(
        deviceName: String,
        config: ViewImageConfig,
        messages: [UIChatMessage]
    ) throws {
        let sut = makeSUT(messages: messages)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "GoodBye View - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light, []),
            ("Dark", ColorScheme.dark, []),
            ("Light-with-messages", ColorScheme.light, UIChatMessage.sampleMessages),
            ("Dark-with-messages", ColorScheme.dark, UIChatMessage.sampleMessages),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme,
        messages: [UIChatMessage]
    ) throws {
        let sut = makeSUT(messages: messages)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    @Test(
        "GoodBye View - Accessibility",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall, []),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge, []),
            ("SmallText-with-messages", ContentSizeCategory.extraSmall, UIChatMessage.sampleMessages),
        ])
    func accessibility(
        textName: String,
        textSize: ContentSizeCategory,
        messages: [UIChatMessage]
    ) throws {
        let sut = makeSUT(messages: messages)
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: textName)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        messages: [UIChatMessage] = UIChatMessage.sampleMessages
    ) -> ChatPanel {
        ChatPanel(
            messages: messages,
            onSendMessage: { _ in }
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
