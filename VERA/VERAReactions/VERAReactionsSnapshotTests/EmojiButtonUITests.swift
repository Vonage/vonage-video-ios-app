//
//  Created by Vonage on 12/2/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAReactions

@Suite("EmojiButton UI Tests")
@MainActor
struct EmojiButtonUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "EmojiButton"

    // MARK: - Button State Tests

    @Test(
        "EmojiButton - States",
        arguments: [
            ("Idle", EmojiButtonState.idle),
            ("PickerVisible", EmojiButtonState.pickerVisible),
        ])
    func buttonStates(stateName: String, state: EmojiButtonState) throws {
        let sut = makeSUT(state: state)

        snapshot(sut, named: "State_\(stateName)")
    }

    // MARK: - Color Schemes

    @Test(
        "EmojiButton - Idle Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func idleColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(state: .idle)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: "Idle_\(schemeName)")
    }

    @Test(
        "EmojiButton - Active Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func activeColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(state: .pickerVisible)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: "Active_\(schemeName)")
    }

    // MARK: - Accessibility

    @Test(
        "EmojiButton - Accessibility Sizes",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall),
            ("DefaultText", ContentSizeCategory.medium),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge),
        ])
    func accessibilitySizes(textName: String, textSize: ContentSizeCategory) throws {
        let sut = makeSUT(state: .idle)
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: "Accessibility_\(textName)")
    }

    // MARK: - All States Comparison

    @Test("EmojiButton - All States Side by Side")
    func allStatesSideBySide() throws {
        let sut = HStack(spacing: 20) {
            EmojiButton(state: .idle, action: {})
            EmojiButton(state: .pickerVisible, action: {})
        }
        .padding()
        .background(Color.gray)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .sizeThatFits),
            named: "AllStates",
            record: isRecording,
            testName: "\(snapshotPrefix)_AllStates"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(state: EmojiButtonState) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            EmojiButton(state: state, action: {})
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
            as: .image(precision: 0.99, layout: .fixed(width: 80, height: 80)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
