//
//  Created by Vonage on 15/4/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI
import VERADomain

@Suite("ToastView UI Tests")
@MainActor
struct ToastViewSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = true
    private let snapshotPrefix = "ToastView"

    // MARK: - Toast Mode Tests

    @Test(
        "ToastView - Modes",
        arguments: [
            ("Info", ToastMode.info),
            ("Failure", ToastMode.failure),
            ("Warning", ToastMode.warning),
            ("Success", ToastMode.success),
        ])
    func toastModes(modeName: String, mode: ToastMode) throws {
        let sut = makeSUT(mode: mode)

        snapshot(sut, named: "Mode_\(modeName)")
    }

    // MARK: - Color Scheme Tests

    @Test(
        "ToastView - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(mode: .info)
            .environment(\.colorScheme, scheme)

        snapshot(sut, named: schemeName)
    }

    // MARK: - All Modes Comparison

    @Test("ToastView - All Modes Side by Side")
    func allModesSideBySide() throws {
        let sut = VStack(spacing: 12) {
            ToastView(item: .init(message: "Info message", mode: .info))
            ToastView(item: .init(message: "Failure message", mode: .failure))
            ToastView(item: .init(message: "Warning message", mode: .warning))
            ToastView(item: .init(message: "Success message", mode: .success))
        }
        .padding()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .sizeThatFits),
            named: "AllModes",
            record: isRecording,
            testName: "\(snapshotPrefix)_AllModes"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(mode: ToastMode) -> ToastView {
        ToastView(item: .init(message: "This is a toast message", mode: mode))
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .sizeThatFits),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
