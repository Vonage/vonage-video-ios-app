//
//  Created by Vonage on 15/4/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAArchiving

@Suite("ArchiveList UI Tests")
@MainActor
struct ArchiveListSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "ArchiveList"

    // MARK: - Content State Tests

    @Test(
        "ArchiveList - Content States",
        arguments: [
            "Empty",
            "Populated",
            "Downloading",
            "Transcriptions",
            "TranscriptionPreparing",
            "Unavailable",
        ])
    func contentStates(variant: String) throws {
        let sut: ArchiveList

        switch variant {
        case "Empty":
            sut = makeSUT(archives: [])
        case "Populated":
            sut = makeSUT(archives: sampleDownloadableArchives)
        case "Downloading":
            sut = makeSUT(archives: sampleDownloadingArchives)
        case "Transcriptions":
            sut = makeSUT(archives: sampleTranscriptionArchives)
        case "TranscriptionPreparing":
            sut = makeSUT(archives: samplePreparingTranscriptionArchives)
        case "Unavailable":
            sut = makeSUT(archives: sampleUnavailableArchives)
        default:
            return
        }

        snapshot(sut, named: "Content_\(variant)")
    }

    // MARK: - Color Scheme Tests

    @Test(
        "ArchiveList - Color Schemes",
        arguments: [
            ("Dark", ColorScheme.dark)
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(archives: sampleDownloadableArchives)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Size Class Tests

    @Test(
        "ArchiveList - Size Classes",
        arguments: [
            ("iPad", ViewImageConfig.iPadPro12_9)
        ])
    func sizeClasses(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(archives: sampleDownloadableArchives)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(archives: [ArchiveUIData]) -> ArchiveList {
        ArchiveList(archives: archives)
    }

    private var sampleDownloadableArchives: [ArchiveUIData] {
        [
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                title: "Recording 1",
                subtitle: "Started at: Mon, Aug 4 12:09 PM",
                downloadState: .ready
            ),
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                title: "Recording 2",
                subtitle: "Started at: Mon, Aug 4 12:30 PM",
                downloadState: .ready
            ),
        ]
    }

    private var sampleDownloadingArchives: [ArchiveUIData] {
        [
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                title: "Recording 1",
                subtitle: "Started at: Mon, Aug 4 12:09 PM",
                downloadState: .ready
            ),
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                title: "Your recording is being prepared",
                subtitle: "Please wait while we prepare your downloads",
                downloadState: .preparing
            ),
        ]
    }

    private var sampleTranscriptionArchives: [ArchiveUIData] {
        [
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                kind: .transcription,
                title: "Transcription 1",
                subtitle: "0:30 • 120.0 KB • Created: Mon, Aug 4 12:30 PM",
                downloadState: .ready
            ),
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                title: "Recording 1",
                subtitle: "0:30 • 1.0 MB • Created: Mon, Aug 4 12:09 PM",
                downloadState: .ready
            ),
        ]
    }

    private var samplePreparingTranscriptionArchives: [ArchiveUIData] {
        [
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                kind: .transcription,
                title: "Your transcription is being prepared",
                subtitle: "Please wait while we prepare your downloads",
                downloadState: .preparing
            ),
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                title: "Recording 1",
                subtitle: "0:30 • 1.0 MB • Created: Mon, Aug 4 12:09 PM",
                downloadState: .ready
            ),
        ]
    }

    private var sampleUnavailableArchives: [ArchiveUIData] {
        [
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                kind: .transcription,
                title: "Transcription 1",
                subtitle: "0:30 • 120.0 KB • Created: Mon, Aug 4 12:30 PM",
                downloadState: .unavailable
            ),
            ArchiveUIData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                title: "Recording 1",
                subtitle: "0:30 • 1.0 MB • Created: Mon, Aug 4 12:09 PM",
                downloadState: .unavailable
            ),
        ]
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
