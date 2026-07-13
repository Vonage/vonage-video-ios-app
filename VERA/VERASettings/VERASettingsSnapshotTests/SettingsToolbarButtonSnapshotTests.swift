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

    // MARK: - Comparison with Other Toolbar Items

    @Test(
        "SettingsToolbarButton - Comparison with Toolbar Items",
        arguments: [
            ("comparison_light", ColorScheme.light),
            ("comparison_dark", ColorScheme.dark),
        ])
    func comparisonWithToolbarItems(
        comparisonName: String,
        colorScheme: ColorScheme
    ) async throws {
        // Shows Settings button next to other toolbar items to verify consistent styling
        let sut = HStack(spacing: 16) {
            // Mock Info button (similar toolbar style)
            Button(action: {}) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            // Mock Close button
            Button(action: {}) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            // Settings toolbar button
            makeSUT()
        }
        .environment(\.colorScheme, colorScheme)
        .padding()

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 200, height: 60)),
            named: comparisonName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(comparisonName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT() -> SettingsToolbarButton {
        SettingsToolbarButton {
            SettingsView(viewModel: .preview)
        }
    }
}
