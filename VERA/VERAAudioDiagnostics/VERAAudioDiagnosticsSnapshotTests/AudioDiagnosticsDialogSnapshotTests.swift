//
//  Created by Vonage on 07/07/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAAudioDiagnostics

@Suite("AudioDiagnosticsDialog Snapshot Tests")
@MainActor
struct AudioDiagnosticsDialogSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "AudioDiagnosticsDialog"

    // MARK: - Basic Layout Tests

    @Test(
        "AudioDiagnosticsDialog - Color Schemes",
        arguments: [
            ("iPhone-Light", ColorScheme.light),
            ("iPhone-Dark", ColorScheme.dark),
        ])
    func iPhoneColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    @Test(
        "AudioDiagnosticsDialog - iPad Color Schemes",
        arguments: [
            ("iPad-Light", ColorScheme.light),
            ("iPad-Dark", ColorScheme.dark),
        ])
    func iPadColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.horizontalSizeClass, .regular)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPadPro12_9)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Playback State Tests

    @Test(
        "AudioDiagnosticsDialog - Playback States",
        arguments: [
            ("Stopped", false, 0.0),
            ("Playing", true, 0.7),
        ])
    func playbackStates(stateName: String, isPlaying: Bool, audioLevel: Float) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = isPlaying
        viewModel.currentAudioLevel = audioLevel

        let sut = AnyView(AudioDiagnosticsDialog(viewModel: viewModel))

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }

    // MARK: - Localization Tests

    @Test(
        "AudioDiagnosticsDialog - Localizations",
        arguments: [
            ("English-Stopped", Locale(identifier: "en"), false),
            ("English-Playing", Locale(identifier: "en"), true),
            ("Spanish-Stopped", Locale(identifier: "es"), false),
            ("Spanish-Playing", Locale(identifier: "es"), true),
        ])
    func localizations(localeName: String, locale: Locale, isPlaying: Bool) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = isPlaying
        viewModel.currentAudioLevel = isPlaying ? 0.7 : 0.0

        let sut = AnyView(AudioDiagnosticsDialog(viewModel: viewModel))
            .environment(\.locale, locale)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: localeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(localeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT() -> AnyView {
        let viewModel = makeViewModel()
        return AnyView(AudioDiagnosticsDialog(viewModel: viewModel))
    }

    private func makeViewModel() -> AudioOutputControlViewModel {
        let speakerTestService = MockSpeakerTestService()
        return AudioOutputControlViewModel(speakerTestService: speakerTestService)
    }
}
