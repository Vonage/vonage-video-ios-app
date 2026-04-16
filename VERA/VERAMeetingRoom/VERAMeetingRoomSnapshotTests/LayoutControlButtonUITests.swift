//
//  Created by Vonage on 15/4/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain

@testable import VERAMeetingRoom

@Suite("LayoutControlButton UI Tests")
@MainActor
struct LayoutControlButtonUITests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "LayoutControlButton"

    // MARK: - Layout State Tests

    @Test(
        "LayoutControlButton - Layout States",
        arguments: [
            ("ActiveSpeaker", MeetingRoomLayout.activeSpeaker),
            ("Grid", MeetingRoomLayout.grid),
        ])
    func layoutStates(stateName: String, layout: MeetingRoomLayout) throws {
        let sut = makeSUT(layout: layout)

        snapshot(sut, named: "State_\(stateName)")
    }

    // MARK: - Color Scheme Tests

    @Test(
        "LayoutControlButton - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(layout: .activeSpeaker)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    // MARK: - All States Comparison

    @Test("LayoutControlButton - All States Side by Side")
    func allStatesSideBySide() throws {
        let sut = HStack(spacing: 20) {
            LayoutControlButton(layout: .activeSpeaker)
            LayoutControlButton(layout: .grid)
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

    private func makeSUT(layout: MeetingRoomLayout) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            LayoutControlButton(layout: layout)
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
