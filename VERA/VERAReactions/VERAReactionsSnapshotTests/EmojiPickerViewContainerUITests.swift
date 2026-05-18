//
//  Created by Vonage on 11/2/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERAReactions

@Suite("EmojiPickerViewContainer UI Tests")
@MainActor
struct EmojiPickerViewContainerUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "EmojiPickerViewContainer"

    // MARK: - Core UI Tests

    @Test(
        "EmojiPickerViewContainer - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
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

            EmojiPickerViewContainer(viewModel: viewModel)
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
