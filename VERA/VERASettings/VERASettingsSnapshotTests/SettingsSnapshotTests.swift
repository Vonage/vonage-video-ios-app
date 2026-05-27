//
//  Created by Vonage on 25/2/26.
//

import Combine
import SnapshotTesting
import SwiftUI
import Testing
import VERADomain

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
        "SettingsView - iPhone Color Schemes",
        arguments: [
            ("iPhone-Dark", ColorScheme.dark)
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
            ("iPad-Dark", ColorScheme.dark)
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
        "SettingsView - Settings States",
        arguments: [
            ("default-settings", PublisherSettingsPreferences.default),
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

    // MARK: - Statistics Section Tests

    @Test("Stats section - Publisher and subscribers list (collapsed)")
    func statsListWithPublisherAndSubscribers() throws {
        let (sut, _) = makeSUTWithStats()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 900)),
            named: "stats-list",
            record: isRecording,
            testName: "\(snapshotPrefix)_stats-list"
        )
    }

    @Test("Stats section - Publisher detail (expanded)")
    func statsPublisherDetail() throws {
        let (sut, statsViewModel) = makeSUTWithStats()
        statsViewModel.isPublisherExpanded = true

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 2800)),
            named: "stats-publisher-detail",
            record: isRecording,
            testName: "\(snapshotPrefix)_stats-publisher-detail"
        )
    }

    @Test("Stats section - Subscriber detail (expanded)")
    func statsSubscriberDetail() throws {
        let (sut, statsViewModel) = makeSUTWithStats()
        statsViewModel.expandedSubscribers.insert("conn-1")

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 2600)),
            named: "stats-subscriber-detail",
            record: isRecording,
            testName: "\(snapshotPrefix)_stats-subscriber-detail"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        withStatistics: Bool = false,
        preferences: PublisherSettingsPreferences = .default,
        selectedSection: SettingsSection = .general,
        horizontalSizeClass: UserInterfaceSizeClass = .compact
    ) -> AnyView {
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
                SettingsView(
                    viewModel: viewModel, statisticsViewModel: statsViewModel, selectedSection: selectedSection
                )
                .environment(\.horizontalSizeClass, horizontalSizeClass)
            )
        } else {
            return AnyView(
                SettingsView(viewModel: viewModel, selectedSection: selectedSection)
                    .environment(\.horizontalSizeClass, horizontalSizeClass)
            )
        }
    }

    private func makeSUTWithStats(
        selectedSection: SettingsSection = .stats,
        horizontalSizeClass: UserInterfaceSizeClass = .compact
    ) -> (AnyView, StatisticsViewModel) {
        var preferences = PublisherSettingsPreferences.default
        preferences.senderStatsEnabled = true

        let repository = MockStatsSettingsRepository(initialPreferences: preferences)
        let viewModel = SettingsViewModel(repository: repository, settingsPreference: preferences)
        let statsViewModel = StatisticsViewModel(
            statsDataSource: MockStatsDataSource(initialStats: sampleStats()),
            settingsRepository: repository
        )
        statsViewModel.stats = sampleStats()
        statsViewModel.isStatsEnabled = true

        let view = AnyView(
            SettingsView(
                viewModel: viewModel, statisticsViewModel: statsViewModel, selectedSection: selectedSection
            )
            .environment(\.horizontalSizeClass, horizontalSizeClass)
        )
        return (view, statsViewModel)
    }

    private func contentScrollable(
        _ useScrollableLayout: Bool,
        config: ViewImageConfig
    ) -> Snapshotting<AnyView, UIImage> {
        useScrollableLayout
            ? .image(precision: 0.99, layout: .fixed(width: 390, height: 2800))
            : .image(precision: 0.99, layout: .device(config: config))
    }

    // MARK: - Sample Data

    private static func makeCustomBitratePreferences() async -> PublisherSettingsPreferences {
        var prefs = PublisherSettingsPreferences.default
        prefs.videoBitratePreset = .custom
        prefs.maxVideoBitrate = 2_000_000  // 2 Mbps
        prefs.maxAudioBitrate = 128_000  // 128 kbps
        return prefs
    }

    private static func makeVP8Preferences() async -> PublisherSettingsPreferences {
        var prefs = PublisherSettingsPreferences.default
        prefs.codecPreference = SettingsCodecPreference(
            mode: .manual,
            orderedCodecs: [.vp8, .h264, .vp9]
        )
        return prefs
    }

    private func sampleStats() -> NetworkMediaStats {
        let timestamp: Double = 1_716_300_000
        return NetworkMediaStats(
            publisherName: "Alice",
            sentAudio: AudioSendStats(
                packetsSent: 1000,
                packetsLost: 5,
                bytesSent: 500_000,
                timestamp: timestamp,
                audioCodec: "opus"
            ),
            sentVideo: VideoSendStats(
                packetsSent: 5000,
                packetsLost: 25,
                bytesSent: 2_500_000,
                timestamp: timestamp,
                videoCodec: "VP8",
                videoLayers: [
                    VideoLayerStats(
                        width: 320, height: 180,
                        encodedFrameRate: 15,
                        bitrate: 150_000, totalBitrate: 160_000,
                        codec: "VP8"
                    ),
                    VideoLayerStats(
                        width: 640, height: 360,
                        encodedFrameRate: 24,
                        bitrate: 500_000, totalBitrate: 530_000,
                        codec: "VP8"
                    ),
                    VideoLayerStats(
                        width: 1280, height: 720,
                        encodedFrameRate: 30,
                        bitrate: 1_500_000, totalBitrate: 1_550_000,
                        codec: "VP8",
                        qualityLimitationReason: .bandwidth
                    ),
                ]
            ),
            subscriberStats: [
                SubscriberMediaStats(
                    subscriberID: "conn-1",
                    subscriberName: "Bob",
                    receivedAudio: AudioReceiveStats(
                        packetsReceived: 800,
                        packetsLost: 8,
                        bytesReceived: 400_000,
                        timestamp: timestamp,
                        audioCodec: "opus",
                        estimatedBandwidth: 450_000
                    ),
                    receivedVideo: VideoReceiveStats(
                        packetsReceived: 3500,
                        packetsLost: 30,
                        bytesReceived: 1_750_000,
                        timestamp: timestamp,
                        width: 1280,
                        height: 720,
                        decodedFrameRate: 30,
                        bitrate: 1_500_000,
                        codec: "VP8"
                    ),
                    mediaLinkStats: SubscriberMediaLinkStats(
                        transport: TransportStats(
                            connectionEstimatedBandwidth: 3_000_000,
                            networkCondition: .excellent
                        )
                    )
                ),
                SubscriberMediaStats(
                    subscriberID: "conn-2",
                    subscriberName: "Charlie",
                    receivedAudio: AudioReceiveStats(
                        packetsReceived: 750,
                        packetsLost: 12,
                        bytesReceived: 375_000,
                        timestamp: timestamp,
                        audioCodec: "opus",
                        estimatedBandwidth: 400_000
                    ),
                    receivedVideo: VideoReceiveStats(
                        packetsReceived: 3200,
                        packetsLost: 45,
                        bytesReceived: 1_600_000,
                        timestamp: timestamp,
                        width: 640,
                        height: 480,
                        decodedFrameRate: 24,
                        bitrate: 800_000,
                        codec: "H264",
                        freezeCount: 2,
                        totalFreezesDuration: 500
                    ),
                    mediaLinkStats: SubscriberMediaLinkStats(
                        transport: TransportStats(
                            connectionEstimatedBandwidth: 500_000,
                            networkCondition: .warning
                        ),
                        networkDegradationSource: .remote
                    )
                ),
            ],
            publisherMediaLinkStats: PublisherMediaLinkStats(
                transport: TransportStats(
                    connectionEstimatedBandwidth: 2_500_000,
                    networkCondition: .good
                )
            )
        )
    }
}
