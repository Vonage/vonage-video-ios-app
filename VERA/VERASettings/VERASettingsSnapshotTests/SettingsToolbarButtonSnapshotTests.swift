//
//  Created by Vonage on 08/07/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERASettings

@Suite("Settings Toolbar Button Snapshot Tests")
@MainActor
struct SettingsToolbarButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "SettingsToolbarButton"

    // MARK: - Icon-Only Button Tests

    @Test(
        "Settings Toolbar Button - Icon Only Design",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func iconOnlyDesign(schemeName: String, scheme: ColorScheme) throws {
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
            testName: "\(snapshotPrefix)_IconOnly_\(schemeName)"
        )
    }

    // MARK: - Comparison Tests

    @Test(
        "Settings Button Styles Comparison - Toolbar vs Circular",
        arguments: [
            ("comparison_light", ColorScheme.light),
            ("comparison_dark", ColorScheme.dark),
        ])
    func comparisonToolbarVsCircular(
        comparisonName: String,
        colorScheme: ColorScheme
    ) async throws {
        // Compare the icon-only toolbar style with the circular waiting room button
        let sut = ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    // Icon-only toolbar style (new design)
                    makeSUT()
                    Text("Toolbar Style")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                VStack(spacing: 12) {
                    // Circular waiting room style (existing design)
                    SettingsWaitingRoomButton {
                        SettingsView(viewModel: .preview)
                    }
                    Text("Circular Style")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .environment(\.colorScheme, colorScheme)

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 200, height: 300)),
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
