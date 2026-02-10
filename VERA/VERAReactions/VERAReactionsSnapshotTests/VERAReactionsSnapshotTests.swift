//
//  Created by Vonage on 2/9/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERAReactions

@Suite("EmojiPickerView UI Tests")
@MainActor
struct EmojiPickerViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "EmojiPickerView"

    // MARK: - Core UI Tests

    @Test(
        "EmojiPickerView - Basic Layout",
        arguments: [
            ("default", EmojiPickerConfiguration.default),
        ])
    func basicLayout(variant: String, configuration: EmojiPickerConfiguration) throws {
        let sut = makeSUT(configuration: configuration)

        snapshot(sut, named: "Default-\(variant)")
    }

    @Test(
        "EmojiPickerView - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPad", ViewImageConfig.iPadPro12_9),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
        ])
    func sizeClasses(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "EmojiPickerView - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
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
        "EmojiPickerView - Accessibility",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge),
        ])
    func accessibility(textName: String, textSize: ContentSizeCategory) throws {
        let sut = makeSUT()
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: textName)
    }

    @Test("EmojiPickerView - Custom Emojis")
    func customEmojis() throws {
        let customConfig = EmojiPickerConfiguration(
            emojis: [
                EmojiItem(emoji: "🎉", name: "party"),
                EmojiItem(emoji: "🔥", name: "fire"),
                EmojiItem(emoji: "💯", name: "hundred"),
            ]
        )
        let sut = makeSUT(configuration: customConfig)

        snapshot(sut, named: "CustomEmojis")
    }

    @Test("EmojiPickerView - Few Emojis")
    func fewEmojis() throws {
        let config = EmojiPickerConfiguration(
            emojis: Array(EmojiItem.defaultEmojis.prefix(5))
        )
        let sut = makeSUT(configuration: config)

        snapshot(sut, named: "FewEmojis")
    }

    // MARK: - Test Helpers

    private func makeSUT(
        configuration: EmojiPickerConfiguration = .default
    ) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            EmojiPickerViewFactory.make(configuration: configuration) { _ in }
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
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
