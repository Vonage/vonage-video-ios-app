//
//  Created by Vonage on 10/06/2026.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAFeedback

@Suite("Feedback Component Button Snapshot Tests")
@MainActor
struct FeedbackComponentButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "FeedbackComponentButton"

    // MARK: - Button Comparison

    @Test(
        "FeedbackComponentButton - Color Schemes",
        arguments: [
            ("comparison_light", ColorScheme.light),
            ("comparison_dark", ColorScheme.dark),
        ])
    func colorSchemeComparison(
        comparisonName: String,
        colorScheme: ColorScheme
    ) throws {
        let sut = ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack(spacing: 12) {
                FeedbackComponentButton(onShowFeedbackForm: {})
                Text("Meeting Room")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .environment(\.colorScheme, colorScheme)

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 300, height: 200)),
            named: comparisonName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(comparisonName)"
        )
    }
}
