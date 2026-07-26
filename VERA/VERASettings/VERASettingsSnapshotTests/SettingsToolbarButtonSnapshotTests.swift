//
//  Created by Vonage on 08/07/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERASettings

@Suite("SettingsToolbarButton Snapshot Tests")
@MainActor
struct SettingsToolbarButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "SettingsToolbarButton"

    // MARK: - Color Scheme Tests

    @Test(
        "SettingsToolbarButton - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = ZStack {
            Color.gray.opacity(0.3)
                .ignoresSafeArea()

            makeSUT()
        }
        .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 80, height: 80)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT() -> SettingsToolbarButton {
        SettingsToolbarButton {
            SettingsView(viewModel: .preview)
        }
    }
}
