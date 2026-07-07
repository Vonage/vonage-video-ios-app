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
        "AudioDiagnosticsDialog - Device Layouts",
        arguments: [
            ("iPhone-13", ViewImageConfig.iPhone13),
            ("iPhone-13-Pro-Max", ViewImageConfig.iPhone13ProMax),
            ("iPhone-SE", ViewImageConfig.iPhoneSe),
        ])
    func deviceLayouts(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "AudioDiagnosticsDialog - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
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

    // MARK: - Playback State Tests

    @Test(
        "AudioDiagnosticsDialog - Playback States",
        arguments: [
            ("Stopped", false, 0.0),
            ("Playing-Low", true, 0.3),
            ("Playing-Medium", true, 0.6),
            ("Playing-High", true, 0.9),
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
            ("English", Locale(identifier: "en")),
            ("Spanish", Locale(identifier: "es")),
        ])
    func localizations(localeName: String, locale: Locale) throws {
        let sut = makeSUT()
            .environment(\.locale, locale)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: localeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(localeName)"
        )
    }

    @Test(
        "AudioDiagnosticsDialog - Spanish Playing State",
        arguments: [
            ("Spanish-Stopped", false),
            ("Spanish-Playing", true),
        ])
    func spanishPlaybackStates(stateName: String, isPlaying: Bool) throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = isPlaying
        viewModel.currentAudioLevel = isPlaying ? 0.7 : 0.0

        let sut = AnyView(AudioDiagnosticsDialog(viewModel: viewModel))
            .environment(\.locale, Locale(identifier: "es"))

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }

    // MARK: - iPad Layout Tests

    @Test(
        "AudioDiagnosticsDialog - iPad Layouts",
        arguments: [
            ("iPad-Pro-11", ViewImageConfig.iPadPro11),
            ("iPad-Pro-12_9", ViewImageConfig.iPadPro12_9),
        ])
    func iPadLayouts(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT()
            .environment(\.horizontalSizeClass, .regular)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test("AudioDiagnosticsDialog - iPad Dark Mode Playing")
    func iPadDarkModePlaying() throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = true
        viewModel.currentAudioLevel = 0.8

        let sut = AnyView(AudioDiagnosticsDialog(viewModel: viewModel))
            .environment(\.horizontalSizeClass, .regular)
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPadPro12_9)),
            named: "iPad-Dark-Playing",
            record: isRecording,
            testName: "\(snapshotPrefix)_iPad-Dark-Playing"
        )
    }

    // MARK: - Fixed Size Tests (for scrollable content)

    @Test("AudioDiagnosticsDialog - Compact Width")
    func compactWidth() throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 320, height: 600)),
            named: "Compact-Width",
            record: isRecording,
            testName: "\(snapshotPrefix)_Compact-Width"
        )
    }

    @Test("AudioDiagnosticsDialog - Standard Height")
    func standardHeight() throws {
        let viewModel = makeViewModel()
        viewModel.isPlaying = true
        viewModel.currentAudioLevel = 0.5

        let sut = AnyView(AudioDiagnosticsDialog(viewModel: viewModel))

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 700)),
            named: "Standard-Height-Playing",
            record: isRecording,
            testName: "\(snapshotPrefix)_Standard-Height-Playing"
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
