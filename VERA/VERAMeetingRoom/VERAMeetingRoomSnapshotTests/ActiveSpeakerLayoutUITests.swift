//
//  Created by Vonage on 12/8/25.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERACore
@testable import VERAMeetingRoom

@Suite("Active speaker layout UI Tests")
@MainActor
struct ActiveSpeakerLayoutUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "ActiveSpeakerLayout"

    // MARK: - Core UI Tests

    @Test("Active Speaker Layout - Basic Layout")
    func basicLayout() throws {
        let sut = makeSUT()

        snapshot(sut, named: "Default")
    }

    @Test(
        "Active Speaker Layout - Size Classes",
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
        "Active Speaker Layout - Color Schemes",
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

    private func makeSUT() -> ActiveSpeakerLayout {
        return ActiveSpeakerLayout(
            participants: PreviewData.uiManyParticipants,
            activeSpeakerId: PreviewData.arthurDent.id)
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
