//
//  Created by Vonage on 07/07/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAAudioDiagnostics

@Suite("AudioOutputControlPanel Snapshot Tests")
@MainActor
struct AudioOutputControlPanelSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "AudioOutputControlPanel"

    // MARK: - Playback State Tests

    @Test(
        "AudioOutputControlPanel - Playback States",
        arguments: [
            ("Stopped", false, 0.0),
            ("Playing-Silent", true, 0.0),
            ("Playing-Low", true, 0.2),
            ("Playing-Medium", true, 0.5),
            ("Playing-High", true, 0.8),
            ("Playing-Max", true, 1.0),
        ])
    func playbackStates(stateName: String, isPlaying: Bool, audioLevel: Float) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = isPlaying
        viewModel.currentAudioLevel = audioLevel

        let sut = AnyView(
            AudioOutputControlPanel(viewModel: viewModel)
                .padding()
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 120)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }

    // MARK: - Color Scheme Tests

    @Test(
        "AudioOutputControlPanel - Color Schemes",
        arguments: [
            ("Light-Stopped", ColorScheme.light, false, 0.0),
            ("Light-Playing", ColorScheme.light, true, 0.7),
            ("Dark-Stopped", ColorScheme.dark, false, 0.0),
            ("Dark-Playing", ColorScheme.dark, true, 0.7),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme,
        isPlaying: Bool,
        audioLevel: Float
    ) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = isPlaying
        viewModel.currentAudioLevel = audioLevel

        let sut = AnyView(
            AudioOutputControlPanel(viewModel: viewModel)
                .padding()
                .environment(\.colorScheme, scheme)
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 120)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Localization Tests

    @Test(
        "AudioOutputControlPanel - English Localization",
        arguments: [
            ("English-Stopped", false),
            ("English-Playing", true),
        ])
    func englishLocalization(stateName: String, isPlaying: Bool) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = isPlaying
        viewModel.currentAudioLevel = isPlaying ? 0.6 : 0.0

        let sut = AnyView(
            AudioOutputControlPanel(viewModel: viewModel)
                .padding()
                .environment(\.locale, Locale(identifier: "en"))
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 120)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }

    @Test(
        "AudioOutputControlPanel - Spanish Localization",
        arguments: [
            ("Spanish-Stopped", false),
            ("Spanish-Playing", true),
        ])
    func spanishLocalization(stateName: String, isPlaying: Bool) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = isPlaying
        viewModel.currentAudioLevel = isPlaying ? 0.6 : 0.0

        let sut = AnyView(
            AudioOutputControlPanel(viewModel: viewModel)
                .padding()
                .environment(\.locale, Locale(identifier: "es"))
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 120)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }

    // MARK: - Audio Level Variations

    @Test(
        "AudioOutputControlPanel - Audio Level Steps",
        arguments: [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0].enumerated().map { ($0, $1) }
    )
    func audioLevelSteps(index: Int, level: Float) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = true
        viewModel.currentAudioLevel = level

        let sut = AnyView(
            AudioOutputControlPanel(viewModel: viewModel)
                .padding()
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 120)),
            named: "Level-\(String(format: "%.1f", level))",
            record: isRecording,
            testName: "\(snapshotPrefix)_Level-\(index)"
        )
    }

    // MARK: - Compact Width Tests

    @Test("AudioOutputControlPanel - Compact Width")
    func compactWidth() throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = true
        viewModel.currentAudioLevel = 0.5

        let sut = AnyView(
            AudioOutputControlPanel(viewModel: viewModel)
                .padding()
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 320, height: 120)),
            named: "Compact-Width",
            record: isRecording,
            testName: "\(snapshotPrefix)_Compact-Width"
        )
    }

    @Test("AudioOutputControlPanel - Wide Layout")
    func wideLayout() throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = true
        viewModel.currentAudioLevel = 0.75

        let sut = AnyView(
            AudioOutputControlPanel(viewModel: viewModel)
                .padding()
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 600, height: 120)),
            named: "Wide-Layout",
            record: isRecording,
            testName: "\(snapshotPrefix)_Wide-Layout"
        )
    }

    // MARK: - Test Helpers

    private func makeViewModel() -> AudioOutputControlViewModel {
        let speakerTestService = MockSpeakerTestService()
        return AudioOutputControlViewModel(speakerTestService: speakerTestService)
    }
}
