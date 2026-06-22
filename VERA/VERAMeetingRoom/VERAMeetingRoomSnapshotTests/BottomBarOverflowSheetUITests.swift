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

    @Test("BottomBarOverflowSheet - Landscape Scrollable")
    func landscapeScrollable() throws {
        let sut = makeSUT(buttons: [makeHeaderButton()] + makeScrollableGridButtons())

        snapshot(sut, named: "LandscapeScrollable", width: 720, height: 260)
    }

    @Test("BottomBarOverflowSheet - Accessory")
    func accessory() throws {
        let sut = makeSUT(buttons: [makeChatButtonWithAccessory()] + Array(makeGridButtons().dropFirst()))

        snapshot(sut, named: "Accessory")
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

    private func makeScrollableGridButtons() -> [BottomBarButton] {
        makeGridButtons() + [
            .init(id: "captions-button", label: "Captions", image: Image(systemName: "captions.bubble"), action: {}),
            .init(
                id: "share-button", label: "Share Screen", image: Image(systemName: "square.and.arrow.up"), action: {}),
            .init(
                id: "effects-button", label: "Effects", image: Image(systemName: "circle.lefthalf.filled"), action: {}),
            .init(id: "participants-button", label: "Participants", image: Image(systemName: "person.2"), action: {}),
        ]
    }

    private func makeChatButtonWithAccessory() -> BottomBarButton {
        .init(
            id: "chat-button-with-accessory",
            label: "Chat",
            image: Image(systemName: "message"),
            accessory: BottomBarButtonAccessory(placement: .topTrailing) {
                BadgeView(badgeCount: 1)
            },
            action: {}
        )
    }

    private func snapshot(
        _ view: some View,
        named: String,
        width: CGFloat = 390,
        height: CGFloat = 360,
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
