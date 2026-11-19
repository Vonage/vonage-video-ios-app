import Foundation
import Testing
import VERADomain

@testable import VERASettings

@MainActor
@Suite("Settings UI-state ownership")
struct SettingsUIStateOwnershipTests {
    @Test("Background repository values update both statistics presentations")
    func backgroundStatsReachUIState() async {
        let repository = MockSettingsRepository(
            initialPreferences: PublisherSettingsPreferences(senderStatsEnabled: true, statsOverlayEnabled: true))
        let source = InMemoryStatsRepository()
        let statistics = StatisticsViewModel(statsDataSource: source, settingsRepository: repository)
        let overlay = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: source)
        statistics.setup()
        overlay.setup()
        #expect(await waitForState { statistics.isStatsEnabled && overlay.isActive })

        let snapshot = makeStats(codec: "opus")
        await Task.detached { await source.updateStats(snapshot) }.value

        #expect(await waitForState { statistics.stats == snapshot && overlay.statsText.contains("opus") })
    }

    @Test("Removed overlay observers ignore subsequent background stats and settings")
    func stoppedOverlayKeepsItsLastUIState() async throws {
        let repository = MockSettingsRepository(
            initialPreferences: PublisherSettingsPreferences(statsOverlayEnabled: true))
        let source = InMemoryStatsRepository()
        let overlay = StatsOverlayViewModel(settingsRepository: repository, statsDataSource: source)
        overlay.setup()
        #expect(await waitForState { overlay.isActive })

        let initial = makeStats(codec: "opus")
        await Task.detached { await source.updateStats(initial) }.value
        #expect(await waitForState { overlay.statsText.contains("opus") })
        let lastText = overlay.statsText
        overlay.removeObservers()

        let replacement = makeStats(codec: "replacement")
        try await Task.detached {
            await source.updateStats(replacement)
            try await repository.save(PublisherSettingsPreferences(statsOverlayEnabled: false))
        }.value
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }

        #expect(overlay.isActive)
        #expect(overlay.statsText == lastText)
    }

    private func makeStats(codec: String) -> NetworkMediaStats {
        NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 321,
                packetsLost: 0,
                bytesSent: 1234,
                timestamp: 0,
                audioCodec: codec))
    }

    private func waitForState(_ predicate: @MainActor () -> Bool) async -> Bool {
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while !predicate(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
        return predicate()
    }
}
