//
//  Created by Vonage on 4/3/26.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERASettings

@Suite("Statistics ViewModel Tests")
struct StatisticsViewModelTests {

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default values")
    func initializesWithDefaults() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatisticsViewModel(
            statsDataSource: dataSource,
            settingsRepository: repository
        )
        viewModel.setup()

        await delay()

        #expect(viewModel.stats == NetworkMediaStats.empty)
        #expect(viewModel.isStatsEnabled == false)
        
        // Keep objects alive
        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("ViewModel initializes with stats enabled")
    func initializesWithStatsEnabled() async throws {
        let customPrefs = PublisherSettingsPreferences(
            senderStatsEnabled: true
        )
        let repository = MockSettingsRepository(initialPreferences: customPrefs)
        let dataSource = MockStatsDataSource()
        let viewModel = StatisticsViewModel(
            statsDataSource: dataSource,
            settingsRepository: repository
        )
        viewModel.setup()

        // Wait for subscriptions to settle
        await delay()

        #expect(viewModel.isStatsEnabled == true)
        
        // Keep objects alive
        _ = repository
        _ = dataSource
        _ = viewModel
    }

    // MARK: - Stats Enabled Observation Tests

    @Test("ViewModel observes senderStatsEnabled changes")
    func observesSenderStatsEnabled() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatisticsViewModel(
            statsDataSource: dataSource,
            settingsRepository: repository
        )
        viewModel.setup()

        // Wait for initial subscription
        await delay()

        #expect(viewModel.isStatsEnabled == false)

        // Enable stats
        var prefs = await repository.getPreferences()
        prefs.senderStatsEnabled = true
        await repository.save(prefs)

        // Wait for update
        await delay()

        #expect(viewModel.isStatsEnabled == true)

        // Disable stats
        prefs.senderStatsEnabled = false
        await repository.save(prefs)

        // Wait for update
        await delay()

        #expect(viewModel.isStatsEnabled == false)
        
        // Keep objects alive
        _ = repository
        _ = dataSource
        _ = viewModel
    }

    // MARK: - Stats Data Observation Tests

    @Test("ViewModel observes stats updates")
    func observesStatsUpdates() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatisticsViewModel(
            statsDataSource: dataSource,
            settingsRepository: repository
        )
        viewModel.setup()

        // Wait for initial subscription
        await delay()

        #expect(viewModel.stats == NetworkMediaStats.empty)

        // Update with mock stats
        let mockStats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 1000,
                packetsLost: 10,
                bytesSent: 50_000,
                timestamp: Date().timeIntervalSince1970,
                audioCodec: "opus"
            ),
            sentVideo: VideoSendStats(
                packetsSent: 5000,
                packetsLost: 25,
                bytesSent: 2_000_000,
                timestamp: Date().timeIntervalSince1970,
                videoCodec: "VP8"
            )
        )
        await dataSource.updateStats(mockStats)

        // Wait for update
        await delay()

        #expect(viewModel.stats.sentAudio?.packetsSent == 1000)
        #expect(viewModel.stats.sentAudio?.packetsLost == 10)
        #expect(viewModel.stats.sentAudio?.bytesSent == 50_000)
        #expect(viewModel.stats.sentVideo?.packetsSent == 5000)
        #expect(viewModel.stats.sentVideo?.packetsLost == 25)
        
        // Keep objects alive
        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("ViewModel handles multiple stats updates")
    func handlesMultipleStatsUpdates() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatisticsViewModel(
            statsDataSource: dataSource,
            settingsRepository: repository
        )
        viewModel.setup()

        // Wait for initial subscription
        await delay()

        // First update
        let stats1 = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100,
                packetsLost: 1,
                bytesSent: 10_000,
                timestamp: Date().timeIntervalSince1970
            )
        )
        await dataSource.updateStats(stats1)
        
        // Wait for update
        await delay()

        #expect(viewModel.stats.sentAudio?.packetsSent == 100)

        // Second update with different values
        let stats2 = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 200,
                packetsLost: 2,
                bytesSent: 20_000,
                timestamp: Date().timeIntervalSince1970
            )
        )
        await dataSource.updateStats(stats2)
        
        await delay()

        #expect(viewModel.stats.sentAudio?.packetsSent == 200)
        #expect(viewModel.stats.sentAudio?.bytesSent == 20_000)
        
        // Keep objects alive
        _ = repository
        _ = dataSource
        _ = viewModel
    }

    // MARK: - Combined Updates Tests

    @Test("ViewModel handles simultaneous stats and settings updates")
    func handlesSimultaneousUpdates() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatisticsViewModel(
            statsDataSource: dataSource,
            settingsRepository: repository
        )
        viewModel.setup()

        // Wait for initial subscription
        await delay()

        #expect(viewModel.isStatsEnabled == false)
        #expect(viewModel.stats == NetworkMediaStats.empty)

        // Update both simultaneously
        var prefs = await repository.getPreferences()
        prefs.senderStatsEnabled = true
        await repository.save(prefs)

        let mockStats = NetworkMediaStats(
            receivedAudio: AudioReceiveStats(
                packetsReceived: 3000,
                packetsLost: 30,
                bytesReceived: 150_000,
                timestamp: Date().timeIntervalSince1970,
                estimatedBandwidth: 512_000
            )
        )
        await dataSource.updateStats(mockStats)

        // Wait for both updates
        await delay()

        #expect(viewModel.isStatsEnabled == true)
        #expect(viewModel.stats.receivedAudio?.packetsReceived == 3000)
        #expect(viewModel.stats.receivedAudio?.estimatedBandwidth == 512_000)
        
        // Keep objects alive
        _ = repository
        _ = dataSource
        _ = viewModel
    }

    // MARK: - Edge Cases

    @Test("ViewModel handles empty stats correctly")
    func handlesEmptyStats() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatisticsViewModel(
            statsDataSource: dataSource,
            settingsRepository: repository
        )
        viewModel.setup()

        // Wait for initial subscription
        await delay()

        // Explicitly send empty stats
        await dataSource.updateStats(NetworkMediaStats.empty)
        
        // Wait for both updates
        await delay()

        #expect(viewModel.stats == NetworkMediaStats.empty)
        #expect(viewModel.stats.sentAudio == nil)
        #expect(viewModel.stats.sentVideo == nil)
        #expect(viewModel.stats.receivedAudio == nil)
        #expect(viewModel.stats.receivedVideo == nil)
        
        // Keep objects alive
        _ = repository
        _ = dataSource
        _ = viewModel
    }

    @Test("ViewModel handles partial stats correctly")
    func handlesPartialStats() async throws {
        let repository = MockSettingsRepository()
        let dataSource = MockStatsDataSource()
        let viewModel = StatisticsViewModel(
            statsDataSource: dataSource,
            settingsRepository: repository
        )
        viewModel.setup()

        // Wait for initial subscription
        await delay()

        // Send stats with only audio send data
        let partialStats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 500,
                packetsLost: 5,
                bytesSent: 25_000,
                timestamp: Date().timeIntervalSince1970
            )
        )
        await dataSource.updateStats(partialStats)
        
        // Wait for both updates
        await delay()

        #expect(viewModel.stats.sentAudio != nil)
        #expect(viewModel.stats.sentAudio?.packetsSent == 500)
        #expect(viewModel.stats.sentVideo == nil)
        #expect(viewModel.stats.receivedAudio == nil)
        #expect(viewModel.stats.receivedVideo == nil)
        
        // Keep objects alive
        _ = repository
        _ = dataSource
        _ = viewModel
    }
}
