//
//  Created by Vonage on 07/07/26.
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

    // MARK: - Basic Layout Tests

    @Test(
        "AudioDiagnosticsWaitingRoomButton - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)
            .frame(width: 64, height: 64)
            .padding()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 100, height: 100)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    @Test("AudioDiagnosticsWaitingRoomButton - Default Size")
    func defaultSize() throws {
        let sut = makeSUT()
            .padding()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 120, height: 120)),
            named: "Default-Size",
            record: isRecording,
            testName: "\(snapshotPrefix)_Default-Size"
        )
    }

    @Test("AudioDiagnosticsWaitingRoomButton - In Horizontal Stack")
    func inHorizontalStack() throws {
        let sut = HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 64, height: 64)

            makeSUT()

            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 64, height: 64)
        }
        .padding()

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 300, height: 120)),
            named: "In-HStack",
            record: isRecording,
            testName: "\(snapshotPrefix)_In-HStack"
        )
    }

    @Test(
        "AudioDiagnosticsWaitingRoomButton - Different Backgrounds",
        arguments: [
            ("On-White", Color.white),
            ("On-Black", Color.black),
            ("On-Gray", Color.gray),
        ])
    func differentBackgrounds(backgroundName: String, backgroundColor: Color) throws {
        let sut = makeSUT()
            .frame(width: 64, height: 64)
            .padding()
            .background(backgroundColor)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 120, height: 120)),
            named: backgroundName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(backgroundName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT() -> AudioDiagnosticsWaitingRoomButton {
        AudioDiagnosticsWaitingRoomButton(makeDialog: {
            AnyView(
                Text("Mock Dialog")
                    .frame(width: 390, height: 600)
            )
        })
    }
}
