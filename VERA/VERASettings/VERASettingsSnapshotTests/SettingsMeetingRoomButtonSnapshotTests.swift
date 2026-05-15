//
//  Created by Vonage on 5/3/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERASettings

@Suite("Settings Meeting Room Button Snapshot Tests")
@MainActor
struct SettingsMeetingRoomButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "SettingsMeetingRoomButton"

    // MARK: - Both Buttons Comparison

    @Test(
        "Both Buttons Comparison",
        arguments: [
            ("comparison_light", ColorScheme.light),
            ("comparison_dark", ColorScheme.dark),
        ])
    func bothButtonsComparison(
        comparisonName: String,
        colorScheme: ColorScheme
    ) async throws {
        let sut = ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    SettingsWaitingRoomButton {
                        SettingsView(viewModel: .preview)
                    }
                    Text("Waiting Room")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                VStack(spacing: 12) {
                    SettingsMeetingRoomButton {
                        // Empty action for testing
                    }
                    Text("Meeting Room")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .environment(\.colorScheme, colorScheme)

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 300, height: 400)),
            named: comparisonName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(comparisonName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        colorScheme: ColorScheme = .dark
    ) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack {
                Spacer()
                SettingsMeetingRoomButton()
                    .padding(.bottom, 16)
            }
        }
        .environment(\.colorScheme, colorScheme)
    }
}
