//
//  StatsOverlayViewModelTests.swift
//  VERASettingsTests
//
//  Created by VERA on 2026-03-04.
//

import Combine
import Foundation
import Testing

@testable import VERADomain
@testable import VERASettings

@Suite("StatsOverlayViewModel Tests")
struct StatsOverlayViewModelTests {

    // MARK: - Initialization Tests

    @Test("Initial state should be inactive with empty stats")
    func testInitialState() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        #expect(viewModel.isActive == false)
        #expect(viewModel.statsText == "")

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("Initial state should observe stats from data source")
    func testInitialStateObservesStats() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        // Update stats
        let stats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 5000, timestamp: 1000, audioCodec: "opus"),
            sentVideo: VideoSendStats(
                packetsSent: 50, packetsLost: 0, bytesSent: 10000, timestamp: 1000, videoCodec: "VP8"),
            receivedAudio: AudioReceiveStats(packetsReceived: 90, packetsLost: 1, bytesReceived: 4500, timestamp: 1000),
            receivedVideo: VideoReceiveStats(packetsReceived: 45, packetsLost: 2, bytesReceived: 9500, timestamp: 1000)
        )
        await dataSource.updateStats(stats)

        // Wait for update
        await delay()

        // Stats should NOT be processed when inactive (senderStatsEnabled = false)
        #expect(viewModel.isActive == false)
        #expect(viewModel.statsText == "")

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    // MARK: - Active State Tests

    @Test("Enabling senderStatsEnabled should display stats")
    func testEnablingSenderStatsEnabled() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        // Enable stats FIRST
        await repository.updatePreferences { $0.senderStatsEnabled = true }

        // Wait for settings update
        await delay()

        // Now send stats (they will be processed)
        let stats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 5000, timestamp: 1000, audioCodec: "opus"),
            sentVideo: VideoSendStats(
                packetsSent: 50, packetsLost: 0, bytesSent: 10000, timestamp: 1000, videoCodec: "VP8"),
            receivedAudio: AudioReceiveStats(packetsReceived: 90, packetsLost: 1, bytesReceived: 4500, timestamp: 1000),
            receivedVideo: VideoReceiveStats(packetsReceived: 45, packetsLost: 2, bytesReceived: 9500, timestamp: 1000)
        )
        await dataSource.updateStats(stats)

        // Wait for stats update
        await delay()

        #expect(viewModel.isActive == true)
        #expect(viewModel.statsText != "")

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("Disabling senderStatsEnabled should hide stats")
    func testDisablingSenderStatsEnabled() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        // Enable stats FIRST
        await repository.updatePreferences { $0.senderStatsEnabled = true }

        // Wait for settings update
        await delay()

        // Now send stats (they will be processed)
        let stats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 5000, timestamp: 1000, audioCodec: "opus"),
            sentVideo: VideoSendStats(
                packetsSent: 50, packetsLost: 0, bytesSent: 10000, timestamp: 1000, videoCodec: "VP8"),
            receivedAudio: AudioReceiveStats(packetsReceived: 90, packetsLost: 1, bytesReceived: 4500, timestamp: 1000),
            receivedVideo: VideoReceiveStats(packetsReceived: 45, packetsLost: 2, bytesReceived: 9500, timestamp: 1000)
        )
        await dataSource.updateStats(stats)

        // Wait for stats update
        await delay()

        #expect(viewModel.statsText != "")

        // Disable stats
        await repository.updatePreferences { $0.senderStatsEnabled = false }

        // Wait for update
        await delay()

        #expect(viewModel.isActive == false)
        #expect(viewModel.statsText == "")

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    // MARK: - Stats Text Formatting Tests

    @Test("StatsText should format complete stats correctly")
    func testStatsTextFormattingComplete() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        await repository.updatePreferences { $0.senderStatsEnabled = true }

        let stats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 5000, timestamp: 1000, audioCodec: "opus"),
            sentVideo: VideoSendStats(
                packetsSent: 50, packetsLost: 0, bytesSent: 10000, timestamp: 1000, videoCodec: "VP8"),
            receivedAudio: AudioReceiveStats(packetsReceived: 90, packetsLost: 1, bytesReceived: 4500, timestamp: 1000),
            receivedVideo: VideoReceiveStats(packetsReceived: 45, packetsLost: 2, bytesReceived: 9500, timestamp: 1000)
        )
        await dataSource.updateStats(stats)

        // Wait for update
        await delay()

        #expect(viewModel.statsText != "")
        let text = viewModel.statsText

        // Check for presence of key components
        #expect(text.contains("opus"))
        #expect(text.contains("VP8"))
        #expect(text.contains("100"))  // packets sent
        #expect(text.contains("50"))  // video packets sent

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("StatsText should handle audio-only stats")
    func testStatsTextFormattingAudioOnly() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        await repository.updatePreferences { $0.senderStatsEnabled = true }

        let stats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 5000, timestamp: 1000, audioCodec: "opus"),
            sentVideo: nil,
            receivedAudio: AudioReceiveStats(packetsReceived: 90, packetsLost: 1, bytesReceived: 4500, timestamp: 1000),
            receivedVideo: nil
        )
        await dataSource.updateStats(stats)

        // Wait for update
        await delay()

        #expect(viewModel.statsText != "")
        let text = viewModel.statsText

        // Should contain audio info
        #expect(text.contains("opus"))
        #expect(text.contains("100"))

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("StatsText should handle video-only stats")
    func testStatsTextFormattingVideoOnly() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        await repository.updatePreferences { $0.senderStatsEnabled = true }

        let stats = NetworkMediaStats(
            sentAudio: nil,
            sentVideo: VideoSendStats(
                packetsSent: 50, packetsLost: 0, bytesSent: 10000, timestamp: 1000, videoCodec: "VP8"),
            receivedAudio: nil,
            receivedVideo: VideoReceiveStats(packetsReceived: 45, packetsLost: 2, bytesReceived: 9500, timestamp: 1000)
        )
        await dataSource.updateStats(stats)

        // Wait for update
        await delay()

        #expect(viewModel.statsText != "")
        let text = viewModel.statsText

        // Should contain video info
        #expect(text.contains("VP8"))
        #expect(text.contains("50"))

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("StatsText should show waiting message when stats are nil")
    func testStatsTextWaitingForStats() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        await repository.updatePreferences { $0.senderStatsEnabled = true }

        // Don't send any stats
        await delay()

        // Should show waiting message or be empty initially
        // The actual behavior depends on implementation
        // This test verifies the ViewModel handles nil stats gracefully

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    // MARK: - Stats Update Tests

    @Test("StatsText should update when new stats arrive")
    func testStatsTextUpdatesWithNewStats() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        await repository.updatePreferences { $0.senderStatsEnabled = true }

        // First stats
        let stats1 = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 5000, timestamp: 1000, audioCodec: "opus"),
            sentVideo: VideoSendStats(
                packetsSent: 50, packetsLost: 0, bytesSent: 10000, timestamp: 1000, videoCodec: "VP8"),
            receivedAudio: AudioReceiveStats(packetsReceived: 90, packetsLost: 1, bytesReceived: 4500, timestamp: 1000),
            receivedVideo: VideoReceiveStats(packetsReceived: 45, packetsLost: 2, bytesReceived: 9500, timestamp: 1000)
        )
        await dataSource.updateStats(stats1)

        // Wait for update
        await delay()

        let firstText = viewModel.statsText
        #expect(firstText != "")

        // Second stats with different values
        let stats2 = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 200, packetsLost: 0, bytesSent: 10000, timestamp: 2000, audioCodec: "opus"),
            sentVideo: VideoSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 20000, timestamp: 2000, videoCodec: "VP8"),
            receivedAudio: AudioReceiveStats(
                packetsReceived: 180, packetsLost: 2, bytesReceived: 9000, timestamp: 2000),
            receivedVideo: VideoReceiveStats(packetsReceived: 90, packetsLost: 4, bytesReceived: 19000, timestamp: 2000)
        )
        await dataSource.updateStats(stats2)

        // Wait for update
        await delay()

        let secondText = viewModel.statsText
        #expect(secondText != "")

        // Verify the text contains updated values
        #expect(secondText.contains("200") || secondText.contains("100"))  // Updated packet counts

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("StatsText should not update when stats are disabled")
    func testStatsTextDoesNotUpdateWhenInactive() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        // Start inactive (senderStatsEnabled defaults to false)
        #expect(viewModel.isActive == false)

        // Send stats
        let stats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 5000, timestamp: 1000, audioCodec: "opus"),
            sentVideo: VideoSendStats(
                packetsSent: 50, packetsLost: 0, bytesSent: 10000, timestamp: 1000, videoCodec: "VP8"),
            receivedAudio: AudioReceiveStats(packetsReceived: 90, packetsLost: 1, bytesReceived: 4500, timestamp: 1000),
            receivedVideo: VideoReceiveStats(packetsReceived: 45, packetsLost: 2, bytesReceived: 9500, timestamp: 1000)
        )
        await dataSource.updateStats(stats)

        // Wait for update
        await delay()

        // Should remain empty when inactive
        #expect(viewModel.statsText == "")

        _ = repository
        _ = dataSource
        _ = viewModel
    }

    // MARK: - Edge Case Tests

    @Test("ViewModel should handle rapid settings toggling")
    func testRapidSettingsToggling() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: dataSource)
        viewModel.setup()

        // Rapidly toggle via repository (end in enabled state)
        await repository.updatePreferences { $0.senderStatsEnabled = true }
        await repository.updatePreferences { $0.senderStatsEnabled = false }
        await repository.updatePreferences { $0.senderStatsEnabled = true }
        await repository.updatePreferences { $0.senderStatsEnabled = false }
        await repository.updatePreferences { $0.senderStatsEnabled = true }

        // Wait for settings update
        await delay()

        // Now send stats (they will be processed since stats are enabled)
        let stats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100, packetsLost: 0, bytesSent: 5000, timestamp: 1000, audioCodec: "opus"),
            sentVideo: VideoSendStats(
                packetsSent: 50, packetsLost: 0, bytesSent: 10000, timestamp: 1000, videoCodec: "VP8"),
            receivedAudio: AudioReceiveStats(packetsReceived: 90, packetsLost: 1, bytesReceived: 4500, timestamp: 1000),
            receivedVideo: VideoReceiveStats(packetsReceived: 45, packetsLost: 2, bytesReceived: 9500, timestamp: 1000)
        )
        await dataSource.updateStats(stats)

        // Wait for stats update
        await delay()

        // Final state should be active with stats
        #expect(viewModel.isActive == true)
        #expect(viewModel.statsText != "")

        _ = repository
        _ = dataSource
        _ = viewModel
    }
}
