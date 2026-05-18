//
//  Created by Vonage on 12/2/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAReactions

@Suite("EmojiButtonContainer UI Tests")
@MainActor
struct EmojiButtonContainerUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "EmojiButtonContainer"

    // MARK: - Button State Tests

    @Test("EmojiButtonContainer - Idle State")
    func idleState() throws {
        let sut = makeSUT(pickerVisible: false)

        snapshot(sut, named: "Idle")
    }

    // MARK: - Color Schemes

    @Test(
        "EmojiButtonContainer - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(pickerVisible: true)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: "PickerVisible_\(schemeName)", config: .iPhone13)
    }

    // MARK: - Test Helpers

    private func makeSUT(pickerVisible: Bool = false) -> some View {
        let viewModel = EmojiButtonContainerViewModel(
            sendReactionUseCase: MockSendReactionUseCase()
        )

        if pickerVisible {
            viewModel.showPicker()
        }

        return ZStack {
            Color.gray.ignoresSafeArea()

            VStack {
                Spacer()
                EmojiButtonContainer(viewModel: viewModel)
                    .padding(.bottom, 50)
            }
        }
    }

    private func snapshot(
        _ view: some View,
        named: String,
        config: ViewImageConfig = .iPhone13,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}

// MARK: - Mock

private struct MockSendReactionUseCase: SendReactionUseCase {
    func callAsFunction(_ emoji: String) throws {
        // No-op for snapshot tests
    }
}
