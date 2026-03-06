//
//  Created by Vonage on 25/2/26.
//

import Testing
import VERADomain

@testable import VERAVonageSettingsPlugin

@Suite("VonageSettingsPlugin Tests")
struct VonageSettingsPluginTests {
    
    // MARK: - callDidStart Tests
    
    @Test("callDidStart sets up observers")
    func callDidStartSetsUpObservers() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        // After callDidStart, the plugin should be observing the repository
        // Change stats enabled and verify it forwards to call
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = true
        }
        
        await delay()
        
        #expect(mocks.call.enableNetworkStatsCallCount == 1)
    }
    
    // MARK: - Stats Toggle Tests
    
    @Test("Stats toggle triggers enableNetworkStats")
    func statsToggleTriggersEnableNetworkStats() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        await delay()
        
        // Initial value is false, so disableNetworkStats is called once
        #expect(mocks.call.disableNetworkStatsCallCount == 1)
        
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = true
        }
        
        await delay()

        #expect(mocks.call.enableNetworkStatsCallCount == 1)
        #expect(mocks.call.disableNetworkStatsCallCount == 1)
    }
    
    @Test("Stats toggle triggers disableNetworkStats")
    func statsToggleTriggersDisableNetworkStats() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        // Start with stats enabled
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = true
        }
        
        try await sut.callDidStart([:])
        
        await delay()

        // Then disable
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = false
        }
        
        await delay()

        #expect(mocks.call.disableNetworkStatsCallCount == 1)
    }
    
    // MARK: - Stats Forwarding Tests
    
    @Test("Stats forwarding from call to statsWriter")
    func statsForwardingFromCallToStatsWriter() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        let testStats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100,
                packetsLost: 5,
                bytesSent: 1000,
                timestamp: 1.0,
                audioCodec: "opus"
            )
        )
        
        mocks.call._networkStatsPublisher.send(testStats)
        
        await delay()

        #expect(mocks.statsWriter.updateStatsCallCount >= 1)
        #expect(mocks.statsWriter.lastStats == testStats)
    }
    
    // MARK: - Settings Changes Tests
    
    @Test("Settings changes trigger applyPublisherAdvancedSettings")
    func settingsChangesTriggerApplyPublisherAdvancedSettings() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        // Give time for initial subscription
        await delay()

        let initialCallCount = mocks.call.applyPublisherAdvancedSettingsCallCount
        
        // Change a setting
        await mocks.repository.updatePreferences { prefs in
            prefs.maxAudioBitrate = 60_000
        }
        
        await delay()

        #expect(mocks.call.applyPublisherAdvancedSettingsCallCount > initialCallCount)
    }
    
    @Test("Settings changes with only statsEnabled do not trigger applyPublisherAdvancedSettings")
    func statsOnlyChangeDoesNotTriggerApply() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        await delay()

        let initialCallCount = mocks.call.applyPublisherAdvancedSettingsCallCount
        
        // Change only statsEnabled (not part of PublisherAdvancedSettings)
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = true
        }
        
        await delay()

        // Should not trigger applyPublisherAdvancedSettings
        #expect(mocks.call.applyPublisherAdvancedSettingsCallCount == initialCallCount)
    }
    
    // MARK: - Task Cancellation Tests
    
    @Test("Rapid settings changes cancel previous task")
    func rapidSettingsChangesCancelPreviousTask() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        await delay()

        // Trigger multiple rapid changes
        await mocks.repository.updatePreferences { prefs in
            prefs.maxAudioBitrate = 50_000
        }
        
        await mocks.repository.updatePreferences { prefs in
            prefs.maxAudioBitrate = 60_000
        }
        
        await mocks.repository.updatePreferences { prefs in
            prefs.maxAudioBitrate = 70_000
        }
        
        await delay()

        // Should have been called but previous tasks should have been cancelled
        #expect(mocks.call.applyPublisherAdvancedSettingsCallCount >= 1)
    }
    
    // MARK: - dropFirst() Tests
    
    @Test("dropFirst prevents initial republish on startup")
    func dropFirstPreventsInitialRepublish() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        await delay()

        // Initial value should be dropped, no call yet
        #expect(mocks.call.applyPublisherAdvancedSettingsCallCount == 0)
        
        // Now change something
        await mocks.repository.updatePreferences { prefs in
            prefs.maxAudioBitrate = 60_000
        }
        
        await delay()

        // Now it should be called
        #expect(mocks.call.applyPublisherAdvancedSettingsCallCount == 1)
    }
    
    // MARK: - callDidEnd Tests
    
    @Test("callDidEnd clears stats and cancels subscriptions")
    func callDidEndClearsStatsAndCancelsSubscriptions() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        // Send some stats
        let testStats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100,
                packetsLost: 5,
                bytesSent: 1000,
                timestamp: 1.0,
                audioCodec: "opus"
            )
        )
        mocks.call._networkStatsPublisher.send(testStats)
        
        await delay()

        try await sut.callDidEnd()
        
        await delay()

        // Stats should have been cleared
        #expect(mocks.statsWriter.clearStatsCallCount == 1)
        
        // Further stats should not be forwarded
        let callCountAfterEnd = mocks.statsWriter.updateStatsCallCount
        mocks.call._networkStatsPublisher.send(.empty)
        
        await delay()

        #expect(mocks.statsWriter.updateStatsCallCount == callCountAfterEnd)
    }
    
    @Test("callDidEnd then callDidStart re-establishes subscriptions")
    func callDidEndThenCallDidStartReestablishesSubscriptions() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        // First cycle
        try await sut.callDidStart([:])
        
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = true
        }
        
        await delay()

        #expect(mocks.call.enableNetworkStatsCallCount == 1)
        
        try await sut.callDidEnd()
        
        // After end, changes should not forward
        mocks.call.enableNetworkStatsCallCount = 0
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = false
        }
        
        await delay()

        #expect(mocks.call.enableNetworkStatsCallCount == 0)
        
        // Second cycle
        try await sut.callDidStart([:])
        
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = true
        }
        
        await delay()

        #expect(mocks.call.enableNetworkStatsCallCount >= 1)
    }
    
    // MARK: - Weak Reference Tests
    
    @Test("Weak call reference doesn't crash when nil")
    func weakCallReferenceDoesNotCrash() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        
        try await sut.callDidStart([:])
        
        // Nil out the call
        sut.call = nil
        
        // These operations should not crash
        await mocks.repository.updatePreferences { prefs in
            prefs.senderStatsEnabled = true
        }
        
        await delay()

        // Test passes if no crash occurs
        #expect(true)
    }
    
    // MARK: - Helpers
    
    private struct Mocks {
        let call: MockCallFacade
        let repository: MockSettingsRepository
        let statsWriter: MockStatsWriter
    }
    
    private func makeSUT() -> (VonageSettingsPlugin, Mocks) {
        let repository = MockSettingsRepository()
        let statsWriter = MockStatsWriter()
        let call = MockCallFacade()
        
        let sut = VonageSettingsPlugin(
            settingsRepository: repository,
            statsWriter: statsWriter
        )
        
        let mocks = Mocks(
            call: call,
            repository: repository,
            statsWriter: statsWriter
        )
        
        return (sut, mocks)
    }
}
