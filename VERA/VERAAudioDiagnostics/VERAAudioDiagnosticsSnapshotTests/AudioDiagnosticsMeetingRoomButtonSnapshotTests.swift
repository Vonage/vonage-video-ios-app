//
//  Created by Vonage on 08/07/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAAudioDiagnostics

@Suite("AudioDiagnosticsMeetingRoomButton Snapshot Tests")
@MainActor
struct AudioDiagnosticsMeetingRoomButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "AudioDiagnosticsMeetingRoomButton"

    // MARK: - Color Scheme Tests

    @Test(
        "AudioDiagnosticsMeetingRoomButton - Color Schemes",
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

    private func makeSUT() -> AudioDiagnosticsMeetingRoomButton {
        AudioDiagnosticsMeetingRoomButton()
    }
}
