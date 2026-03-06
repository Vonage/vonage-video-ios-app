//
//  Created by Vonage on 25/2/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain
import Combine

@testable import VERASettings

@Suite("Settings Snapshot Tests")
@MainActor
struct SettingsSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "SettingsView"

    // MARK: - Core UI Tests

    @Test(
        "SettingsView - Basic Layouts",
        arguments: [
            ("compact-waiting-room", false, false),
            ("compact-meeting-room", true, true),
        ])
    func basicLayouts(variant: String, withStats: Bool, useScrollableLayout: Bool) throws {
        let sut = makeSUT(withStatistics: withStats, horizontalSizeClass: .compact)

        assertSnapshot(
            of: sut,
            as: contentScrollable(useScrollableLayout, config: .iPhone13),
            named: variant,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(variant)"
        )
    }

    @Test(
        "SettingsView - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13, false, UserInterfaceSizeClass.compact, false),
            ("iPad", ViewImageConfig.iPadPro12_9, false, UserInterfaceSizeClass.regular, false),
            ("iPhone-with-stats", ViewImageConfig.iPhone13, true, UserInterfaceSizeClass.compact, true),
            ("iPad-with-stats", ViewImageConfig.iPadPro12_9, true, UserInterfaceSizeClass.regular, false),
        ])
    func sizeClasses(
        deviceName: String,
        config: ViewImageConfig,
        withStats: Bool,
        horizontalSizeClass: UserInterfaceSizeClass,
        useScrollableLayout: Bool
    ) throws {
        let sut = makeSUT(withStatistics: withStats, horizontalSizeClass: horizontalSizeClass)

        assertSnapshot(
            of: sut,
            as: contentScrollable(useScrollableLayout, config: config),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "SettingsView - iPhone Color Schemes",
        arguments: [
            ("iPhone-Light", ColorScheme.light),
            ("iPhone-Dark", ColorScheme.dark),
        ])
    func iPhoneColorSchemes(
        schemeName: String,
        scheme: ColorScheme
    ) throws {
        let sut = makeSUT(withStatistics: false, horizontalSizeClass: .compact)
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
        "SettingsView - iPad Color Schemes",
        arguments: [
            ("iPad-Light", ColorScheme.light),
            ("iPad-Dark", ColorScheme.dark),
        ])
    func iPadColorSchemes(
        schemeName: String,
        scheme: ColorScheme
    ) throws {
        let sut = makeSUT(withStatistics: false, horizontalSizeClass: .regular)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPadPro12_9)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    @Test(
        "SettingsView - Accessibility",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall),
            ("LargeText", ContentSizeCategory.accessibilityExtraLarge),
        ])
    func accessibility(
        textName: String,
        textSize: ContentSizeCategory
    ) throws {
        let sut = makeSUT(withStatistics: false, horizontalSizeClass: .compact)
            .environment(\.sizeCategory, textSize)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: textName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(textName)"
        )
    }

    @Test(
        "SettingsView - Settings States",
        arguments: [
            ("default-settings", PublisherSettingsPreferences.default),
            ("stats-enabled", await makeStatsEnabledPreferences()),
            ("custom-bitrates", await makeCustomBitratePreferences()),
            ("vp8-codec", await makeVP8Preferences()),
        ])
    func settingsStates(
        stateName: String,
        preferences: PublisherSettingsPreferences
    ) throws {
        let sut = makeSUT(withStatistics: false, preferences: preferences, horizontalSizeClass: .compact)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }

    @Test(
        "SettingsView - iPad Sections",
        arguments: [
            ("iPad-general", SettingsSection.general, false),
            ("iPad-video", SettingsSection.video, false),
            ("iPad-audio", SettingsSection.audio, false),
            ("iPad-stats", SettingsSection.stats, true),
        ])
    func iPadSections(
        sectionName: String,
        section: SettingsSection,
        withStats: Bool
    ) throws {
        let sut = makeSUT(
            withStatistics: withStats,
            selectedSection: section,
            horizontalSizeClass: .regular
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPadPro12_9)),
            named: sectionName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(sectionName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        withStatistics: Bool = false,
        preferences: PublisherSettingsPreferences = .default,
        selectedSection: SettingsSection = .general,
        horizontalSizeClass: UserInterfaceSizeClass = .compact
    )  -> AnyView {
        var finalPreferences = preferences
        
        // Enable stats in preferences when statistics view is present
        if withStatistics {
            finalPreferences.senderStatsEnabled = true
        }
        
        let repository = MockStatsSettingsRepository(initialPreferences: finalPreferences)
        let viewModel = SettingsViewModel(repository: repository, settingsPreference: finalPreferences)
        
        if withStatistics {
            let statsViewModel = StatisticsViewModel(
                statsDataSource: MockStatsDataSource(initialStats: sampleStats()),
                settingsRepository: repository
            )
            return AnyView(
                SettingsView(viewModel: viewModel, statisticsViewModel: statsViewModel, selectedSection: selectedSection)
                    .environment(\.horizontalSizeClass, horizontalSizeClass)
            )
        } else {
            return AnyView(
                SettingsView(viewModel: viewModel, selectedSection: selectedSection)
                    .environment(\.horizontalSizeClass, horizontalSizeClass)
            )
        }
    }
    
    private func contentScrollable(
        _ useScrollableLayout: Bool,
        config: ViewImageConfig
    ) -> Snapshotting<AnyView, UIImage> {
         useScrollableLayout
            ? .image(precision: 0.99, layout: .fixed(width: 390, height: 2250))
            : .image(precision: 0.99, layout: .device(config: config))
    }

    // MARK: - Sample Data

    private static func makeStatsEnabledPreferences() async -> PublisherSettingsPreferences {
        var prefs = PublisherSettingsPreferences.default
        prefs.senderStatsEnabled = true
        return prefs
    }

    private static func makeCustomBitratePreferences() async -> PublisherSettingsPreferences {
        var prefs = PublisherSettingsPreferences.default
        prefs.videoBitratePreset = .custom
        prefs.maxVideoBitrate = 2_000_000  // 2 Mbps
        prefs.maxAudioBitrate = 128_000    // 128 kbps
        return prefs
    }

    private static func makeVP8Preferences() async -> PublisherSettingsPreferences {
        var prefs = PublisherSettingsPreferences.default
        prefs.codecPreference = SettingsCodecPreference(
            mode: .manual ,
            orderedCodecs: [.vp8, .h264, .vp9]
        )
        return prefs
    }

    private func sampleStats() -> NetworkMediaStats {
        NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 1000,
                packetsLost: 5,
                bytesSent: 500_000,
                timestamp: Date().timeIntervalSince1970,
                audioCodec: "opus"
            ),
            sentVideo: VideoSendStats(
                packetsSent: 5000,
                packetsLost: 25,
                bytesSent: 2_500_000,
                timestamp: Date().timeIntervalSince1970,
                videoCodec: "VP8"
            ),
            receivedAudio: AudioReceiveStats(
                packetsReceived: 950,
                packetsLost: 10,
                bytesReceived: 475_000,
                timestamp: Date().timeIntervalSince1970,
                estimatedBandwidth: 500_000
            ),
            receivedVideo: VideoReceiveStats(
                packetsReceived: 4800,
                packetsLost: 50,
                bytesReceived: 2_400_000,
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
