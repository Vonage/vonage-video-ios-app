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
            ("Playing", true, 0.7),
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
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = true
        viewModel.currentAudioLevel = 0.7

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
        "AudioOutputControlPanel - Localizations",
        arguments: [
            ("English-Stopped", Locale(identifier: "en"), false),
            ("English-Playing", Locale(identifier: "en"), true),
            ("Spanish-Stopped", Locale(identifier: "es"), false),
            ("Spanish-Playing", Locale(identifier: "es"), true),
        ])
    func localizations(localeName: String, locale: Locale, isPlaying: Bool) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = isPlaying
        viewModel.currentAudioLevel = isPlaying ? 0.6 : 0.0

        let sut = AnyView(
            AudioOutputControlPanel(viewModel: viewModel)
                .padding()
                .environment(\.locale, locale)
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 120)),
            named: localeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(localeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeViewModel() -> AudioOutputControlViewModel {
        let speakerTestService = MockSpeakerTestService()
        return AudioOutputControlViewModel(speakerTestService: speakerTestService)
    }
}
