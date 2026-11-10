//
//  Created by Vonage on 26/10/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI
import VERADomain

@testable import VERAArchiving

@Suite("TranscriptionStartOptions UI Tests")
@MainActor
struct TranscriptionStartOptionsSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "TranscriptionStartOptions"

    // MARK: - Option Tests

    @Test(
        "TranscriptionStartOptions - Options",
        arguments: [
            ("Default", TranscriptionOptions.default),
            ("SummaryOff", TranscriptionOptions(hasSummary: false)),
        ])
    func options(variant: String, options: TranscriptionOptions) throws {
        snapshot(makeSUT(options: options), named: variant)
    }

    // MARK: - Color Scheme Tests

    @Test("TranscriptionStartOptions - Dark")
    func dark() throws {
        snapshot(
            makeSUT(options: .default)
                .environment(\.colorScheme, .dark),
            named: "Dark")
    }

    // MARK: - Test Helpers

    private func makeSUT(options: TranscriptionOptions) -> some View {
        TranscriptionStartOptionsView(
            options: .constant(options),
            onStart: {},
            onCancel: {}
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
        .environment(\.locale, Locale(identifier: "en_US"))
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 300)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
