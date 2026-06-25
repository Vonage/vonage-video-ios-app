//
//  Created by Vonage on 19/06/2026.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERAReactions

@Suite("EmojiHorizontalPickerViewContainer UI Tests")
@MainActor
struct EmojiHorizontalPickerViewContainerUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "EmojiHorizontalPickerViewContainer"

    // MARK: - Core UI Tests

    @Test(
        "EmojiHorizontalPickerViewContainer - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    @Test("EmojiHorizontalPickerViewContainer - Few Emojis")
    func fewEmojis() throws {
        let sut = makeSUT(emojis: Array(UIEmojiReaction.defaultEmojis.prefix(3)))

        snapshot(sut, named: "FewEmojis", width: 220)
    }

    @Test("EmojiHorizontalPickerViewContainer - Narrow Width")
    func narrowWidth() throws {
        let sut = makeSUT()

        snapshot(sut, named: "NarrowWidth", width: 260)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        emojis: [UIEmojiReaction] = UIEmojiReaction.defaultEmojis
    ) -> some View {
        let configuration = EmojiPickerConfiguration(emojis: emojis)

        let viewModel = EmojiPickerContainerViewModel(
            configuration: configuration,
            sendReactionUseCase: MockSendReactionUseCase()
        )

        return ZStack {
            Color.gray
                .ignoresSafeArea()

            EmojiHorizontalPickerViewContainer(viewModel: viewModel)
        }
    }

    private func snapshot(
        _ view: some View,
        named: String,
        width: CGFloat = 390,
        height: CGFloat = 96,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: width, height: height)),
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
