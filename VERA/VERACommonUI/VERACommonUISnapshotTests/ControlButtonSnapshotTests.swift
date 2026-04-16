//
//  Created by Vonage on 15/4/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI

@Suite("ControlButton UI Tests")
@MainActor
struct ControlButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "ControlButton"

    // MARK: - Active State Tests

    @Test(
        "ControlButton - Active States",
        arguments: [
            ("Active", true),
            ("Inactive", false),
        ])
    func activeStates(stateName: String, isActive: Bool) throws {
        let sut = makeSUT(isActive: isActive)

        snapshot(sut, named: "State_\(stateName)")
    }

    // MARK: - Color Scheme Tests

    @Test(
        "ControlButton - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(isActive: true)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    // MARK: - All States Comparison

    @Test("ControlButton - All States Side by Side")
    func allStatesSideBySide() throws {
        let sut = HStack(spacing: 20) {
            ControlButton(isActive: true, iconName: "mic.fill")
            ControlButton(isActive: false, iconName: "mic.slash.fill")
        }
        .padding()
        .background(Color.gray)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .sizeThatFits),
            named: "AllStates",
            record: isRecording,
            testName: "\(snapshotPrefix)_AllStates"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(isActive: Bool) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            ControlButton(isActive: isActive, iconName: "mic.fill")
        }
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: 80, height: 80)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
