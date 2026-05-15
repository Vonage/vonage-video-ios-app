//
//  Created by Vonage on 15/4/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAMeetingRoom

@Suite("ParticipantsBadgeButton UI Tests")
@MainActor
struct ParticipantsBadgeButtonUITests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "ParticipantsBadgeButton"

    // MARK: - Color Scheme Tests

    @Test(
        "ParticipantsBadgeButton - Color Schemes",
        arguments: [
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(participantsCount: 25)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    // MARK: - All Counts Comparison

    @Test("ParticipantsBadgeButton - All Counts Side by Side")
    func allCountsSideBySide() throws {
        let sut = HStack(spacing: 20) {
            ParticipantsBadgeButton(participantsCount: 0, onToggleParticipants: {})
            ParticipantsBadgeButton(participantsCount: 5, onToggleParticipants: {})
            ParticipantsBadgeButton(participantsCount: 99, onToggleParticipants: {})
            ParticipantsBadgeButton(participantsCount: 100, onToggleParticipants: {})
        }
        .padding()
        .background(Color.gray)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .sizeThatFits),
            named: "AllCounts",
            record: isRecording,
            testName: "\(snapshotPrefix)_AllCounts"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(participantsCount: Int) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            ParticipantsBadgeButton(
                participantsCount: participantsCount,
                onToggleParticipants: {}
            )
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
