//
//  Created by Vonage on 19/06/2026.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI

@testable import VERAMeetingRoom

@Suite("BottomBarOverflowSheet UI Tests")
@MainActor
struct BottomBarOverflowSheetUITests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "BottomBarOverflowSheet"

    // MARK: - Core UI Tests

    @Test("BottomBarOverflowSheet - Grid Only")
    func gridOnly() throws {
        let sut = makeSUT(buttons: makeGridButtons())

        snapshot(sut, named: "GridOnly")
    }

    @Test("BottomBarOverflowSheet - Header And Grid")
    func headerAndGrid() throws {
        let sut = makeSUT(buttons: [makeHeaderButton()] + makeGridButtons())

        snapshot(sut, named: "HeaderAndGrid")
    }

    @Test("BottomBarOverflowSheet - Header And Grid Dark")
    func headerAndGridDark() throws {
        let sut = makeSUT(buttons: [makeHeaderButton()] + makeGridButtons())
            .environment(\.colorScheme, .dark)

        snapshot(sut, named: "HeaderAndGrid_Dark")
    }

    // MARK: - Test Helpers

    private func makeSUT(buttons: [BottomBarButton]) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            BottomBarOverflowSheet(buttons: buttons, onSelect: { _ in })
                .background(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
        }
    }

    private func makeHeaderButton() -> BottomBarButton {
        let emojis = ["👍", "👎", "👋", "👏", "🚀", "🎉", "🙏", "💪", "❤️", "😂"]

        return .init(
            id: "reactions-button",
            label: "Reactions",
            image: Image(systemName: "face.smiling"),
            overflowPresentation: .headerContent {
                AnyView(
                    HStack(spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 32))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
            },
            action: {}
        )
    }

    private func makeGridButtons() -> [BottomBarButton] {
        [
            .init(id: "chat-button", label: "Chat", image: Image(systemName: "message"), action: {}),
            .init(id: "settings-button", label: "Settings", image: Image(systemName: "gearshape"), action: {}),
            .init(id: "feedback-button", label: "Feedback", image: Image(systemName: "flag"), action: {}),
            .init(id: "recording-button", label: "Recording", image: Image(systemName: "record.circle"), action: {}),
        ]
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 360)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
