//
//  Created by Vonage on 13/8/25.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERAMeetingRoom

@testable import VERACore

@Suite("Participants List View UI Tests")
@MainActor
struct ParticipantsListViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "ParticipantsList"

    // MARK: - Core UI Tests

    @Test(
        "Participants List View - Size Classes",
        arguments: [
            ("iPad", ViewImageConfig.iPadPro12_9),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
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

    @Test(
        "Participants List View - Color Schemes",
        arguments: [("Dark", ColorScheme.dark)])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT() -> ParticipantsListView {
        ParticipantsListView(
            participants: PreviewData.uiManyParticipants,
            participantsCount: PreviewData.uiManyParticipants.count,
            roomName: "heart-of-gold",
            meetingURL: .init(string: "https://video.vonage.com/heart-of-gold"),
            onDismiss: {})
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
