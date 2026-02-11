//
//  EmojiPickerComponentViewUITests.swift
//  VERAReactionsSnapshotTests
//

import SnapshotTesting
import SwiftUI
import Testing
import VERAReactions

@Suite("EmojiPickerComponentView UI Tests")
@MainActor
struct EmojiPickerComponentViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "EmojiPickerComponentView"

    // MARK: - Core UI Tests

    @Test("EmojiPickerComponentView - Default State")
    func defaultState() throws {
        let sut = makeSUT()

        snapshot(sut, named: "Default")
    }

    @Test(
        "EmojiPickerComponentView - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    @Test(
        "EmojiPickerComponentView - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPad", ViewImageConfig.iPadPro12_9),
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

    @Test("EmojiPickerComponentView - Custom Emojis")
    func customEmojis() throws {
        let customEmojis = [
            UIEmojiReaction(emoji: "🎉", name: "party"),
            UIEmojiReaction(emoji: "🔥", name: "fire"),
            UIEmojiReaction(emoji: "💯", name: "hundred"),
            UIEmojiReaction(emoji: "✨", name: "sparkles"),
        ]
        let sut = makeSUT(emojis: customEmojis)

        snapshot(sut, named: "CustomEmojis")
    }

    @Test("EmojiPickerComponentView - Few Emojis")
    func fewEmojis() throws {
        let sut = makeSUT(emojis: Array(UIEmojiReaction.defaultEmojis.prefix(5)))

        snapshot(sut, named: "FewEmojis")
    }

    // MARK: - iOS 16 Layout Tests

    /// Verifies that grid columns are properly spaced and not collapsed on iOS 16.
    @Test("EmojiPickerComponentView - iOS 16 Grid Layout")
    func iOS16GridLayout() throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: "iOS16_GridLayout",
            record: isRecording,
            testName: "\(snapshotPrefix)_iOS16_GridLayout"
        )
    }

    /// Verifies grid layout with single row (4 emojis)
    @Test("EmojiPickerComponentView - iOS 16 Single Row")
    func iOS16SingleRow() throws {
        let sut = makeSUT(emojis: Array(UIEmojiReaction.defaultEmojis.prefix(4)))

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: "iOS16_SingleRow",
            record: isRecording,
            testName: "\(snapshotPrefix)_iOS16_SingleRow"
        )
    }

    /// Verifies grid layout with two rows (8 emojis)
    @Test("EmojiPickerComponentView - iOS 16 Two Rows")
    func iOS16TwoRows() throws {
        let sut = makeSUT(emojis: Array(UIEmojiReaction.defaultEmojis.prefix(8)))

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: "iOS16_TwoRows",
            record: isRecording,
            testName: "\(snapshotPrefix)_iOS16_TwoRows"
        )
    }

    /// Verifies grid layout on iPad for iOS 16 compatibility
    @Test("EmojiPickerComponentView - iOS 16 iPad Layout")
    func iOS16iPadLayout() throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPadPro12_9)),
            named: "iOS16_iPad",
            record: isRecording,
            testName: "\(snapshotPrefix)_iOS16_iPad"
        )
    }

    /// Verifies grid layout in landscape orientation for iOS 16
    @Test("EmojiPickerComponentView - iOS 16 Landscape")
    func iOS16Landscape() throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13(.landscape))),
            named: "iOS16_Landscape",
            record: isRecording,
            testName: "\(snapshotPrefix)_iOS16_Landscape"
        )
    }

    // MARK: - Accessibility Tests

    @Test(
        "EmojiPickerComponentView - Accessibility",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge),
        ])
    func accessibility(textName: String, textSize: ContentSizeCategory) throws {
        let sut = makeSUT()
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: textName)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        emojis: [UIEmojiReaction] = UIEmojiReaction.defaultEmojis
    ) -> some View {
        let configuration = EmojiPickerConfiguration(emojis: emojis)
    
        let viewModel = EmojiPickerComponentViewModel(
            configuration: configuration,
            sendReactionUseCase: MockSendReactionUseCase()
        )

        return ZStack {
            Color.gray
                .ignoresSafeArea()

            EmojiPickerComponentView(viewModel: viewModel)
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

// MARK: - Mock for Snapshot Tests

private struct MockSendReactionUseCase: SendReactionUseCase {
    func callAsFunction(_ emoji: String) throws {
        // No-op for snapshot tests
    }
}
