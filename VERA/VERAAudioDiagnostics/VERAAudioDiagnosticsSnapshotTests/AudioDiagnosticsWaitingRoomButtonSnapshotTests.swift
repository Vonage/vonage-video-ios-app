//
//  Created by Vonage on 07/07/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAAudioDiagnostics

@Suite("AudioDiagnosticsWaitingRoomButton Snapshot Tests")
@MainActor
struct AudioDiagnosticsWaitingRoomButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "AudioDiagnosticsWaitingRoomButton"

    // MARK: - Basic Layout Tests

    @Test(
        "AudioDiagnosticsWaitingRoomButton - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)
            .frame(width: 64, height: 64)
            .padding()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 100, height: 100)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT() -> AudioDiagnosticsWaitingRoomButton {
        AudioDiagnosticsWaitingRoomButton(makeDialog: {
            AnyView(
                Text("Mock Dialog")
                    .frame(width: 390, height: 600)
            )
        })
    }
}
