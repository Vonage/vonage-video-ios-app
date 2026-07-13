//
//  Created by Vonage on 08/07/26.
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

    // MARK: - Color Scheme Tests

    @Test(
        "AudioDiagnosticsWaitingRoomButton - Color Schemes",
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

    // MARK: - Comparison with Camera Selector Style

    @Test(
        "AudioDiagnosticsWaitingRoomButton - Comparison with Camera Selector",
        arguments: [
            ("comparison_light", ColorScheme.light),
            ("comparison_dark", ColorScheme.dark),
        ])
    func comparisonWithCameraSelector(
        comparisonName: String,
        colorScheme: ColorScheme
    ) async throws {
        // Shows Audio selector next to a mock Camera selector to verify consistent styling
        let sut = HStack(spacing: 16) {
            // Mock Camera selector (same Label style)
            Button(action: {}) {
                Label {
                    Text("Camera")
                } icon: {
                    Image(systemName: "video.fill")
                }
            }

            // Audio button
            makeSUT()
        }
        .environment(\.colorScheme, colorScheme)
        .padding()

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 300, height: 60)),
            named: comparisonName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(comparisonName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT() -> AudioDiagnosticsWaitingRoomButton {
        AudioDiagnosticsWaitingRoomButton(makeView: {
            AnyView(
                Text("Mock View")
                    .frame(width: 390, height: 600)
            )
        })
    }
}
