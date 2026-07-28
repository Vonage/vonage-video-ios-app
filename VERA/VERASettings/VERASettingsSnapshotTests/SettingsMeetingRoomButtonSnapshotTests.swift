//
//  Created by Vonage on 5/3/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERASettings

@Suite("SettingsMeetingRoomButton Snapshot Tests")
@MainActor
struct SettingsMeetingRoomButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "SettingsMeetingRoomButton"

    // MARK: - Color Scheme Tests

    @Test(
        "SettingsMeetingRoomButton - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)
            .padding()

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 150, height: 60)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT() -> SettingsMeetingRoomButton {
        SettingsMeetingRoomButton(onShowSettings: {})
    }
}
