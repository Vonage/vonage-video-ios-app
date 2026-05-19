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
