//
//  Created by Vonage on 20/02/2026.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain

@testable import VERACaptions

@Suite("CaptionsButton UI Tests")
@MainActor
struct CaptionsButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "CaptionsButton"

    // MARK: - Core UI Tests

    @Test(
        "CaptionsButton - Basic Layout",
        arguments: [
            ("disabled", CaptionsState.disabled),
            ("enabled", CaptionsState.enabled("demo-id")),
        ])
    func basicLayout(variant: String, state: CaptionsState) throws {
        let sut = makeSUT(state: state)

        snapshot(sut, named: "Default-\(variant)")
    }

    @Test(
        "CaptionsButton - Size Classes",
        arguments: [
            ("iPhone-disabled", ViewImageConfig.iPhone13, CaptionsState.disabled),
            ("iPhone-enabled", ViewImageConfig.iPhone13, CaptionsState.enabled("demo-id")),
            ("iPad-disabled", ViewImageConfig.iPadPro12_9, CaptionsState.disabled),
            ("iPad-enabled", ViewImageConfig.iPadPro12_9, CaptionsState.enabled("demo-id")),
            ("iPhoneLandscape-enabled", ViewImageConfig.iPhone13(.landscape), CaptionsState.enabled("demo-id")),
        ])
    func sizeClasses(
        deviceName: String,
        config: ViewImageConfig,
        state: CaptionsState
    ) throws {
        let sut = makeSUT(state: state)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "CaptionsButton - Color Schemes",
        arguments: [
            ("Light-disabled", ColorScheme.light, CaptionsState.disabled),
            ("Light-enabled", ColorScheme.light, CaptionsState.enabled("demo-id")),
            ("Dark-disabled", ColorScheme.dark, CaptionsState.disabled),
            ("Dark-enabled", ColorScheme.dark, CaptionsState.enabled("demo-id")),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme,
        state: CaptionsState
    ) throws {
        let sut = makeSUT(state: state)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        state: CaptionsState = .disabled
    ) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack {
                Spacer()
                CaptionsButton(state: state)
            }
            .padding(.bottom, 16)
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
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
