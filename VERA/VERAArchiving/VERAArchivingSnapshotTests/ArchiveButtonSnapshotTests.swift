//
//  Created by Vonage on 11/10/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI
import VERADomain

@testable import VERAArchiving

@Suite("ArchiveButton UI Tests")
@MainActor
struct ArchiveButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "ArchiveButton"

    // MARK: - Kind and State Tests

    @Test(
        "ArchiveButton - Kinds and States",
        arguments: [
            ("Recording_Idle", ArchiveKind.recording, ArchivingState.idle),
            ("Recording_Active", .recording, .archiving("recording-1")),
            ("Transcription_Idle", .transcription, .idle),
            ("Transcription_Active", .transcription, .archiving("transcription-1")),
        ])
    func kindsAndStates(variant: String, kind: ArchiveKind, state: ArchivingState) throws {
        snapshot(makeSUT(kind: kind, state: state), named: variant)
    }

    // MARK: - Color Scheme Tests

    @Test(
        "ArchiveButton - Color Schemes",
        arguments: [
            ("Dark", ColorScheme.dark)
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = HStack(spacing: 20) {
            ArchiveButton(kind: .recording, state: .archiving("recording-1"))
            ArchiveButton(kind: .transcription, state: .idle)
            ArchiveButton(kind: .transcription, state: .archiving("transcription-1"))
        }
        .padding()
        .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
        .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .sizeThatFits),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(kind: ArchiveKind, state: ArchivingState) -> some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ArchiveButton(kind: kind, state: state)
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
