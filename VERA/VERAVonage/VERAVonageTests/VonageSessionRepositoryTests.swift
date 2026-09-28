//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import Testing
import VERACore
import VERADomain
import VERATestHelpers
import VERAVonage

@MainActor
@Suite("VonageSessionRepository tests")
struct VonageSessionRepositoryTests {

    @Test
    func createsSessionSuccessfully() async throws {
        let sessionProvider = MockVonageSessionProvider()
        let publisherRepository = MockPublisherRepository()
        let pluginRegistry = VonagePluginRegistry()
        let statsCollector = MockStatsCollector()

        let sut = makeSUT(
            sessionProvider: sessionProvider,
            publisherRepository: publisherRepository,
            pluginRegistry: pluginRegistry,
            statsCollector: statsCollector
        )

        let call = try await sut.createSession(for: "a-room")

        #expect(sut.currentCall != nil)
        // The session is created lazily on connect, not at createSession time.
        #expect(!sessionProvider.makeSessionCalled)
        _ = call
    }

    @Test
    func clearsSessionSuccessfully() async throws {
        let sessionProvider = MockVonageSessionProvider()
        let publisherRepository = MockPublisherRepository()
        let pluginRegistry = VonagePluginRegistry()
        let statsCollector = MockStatsCollector()

        let sut = makeSUT(
            sessionProvider: sessionProvider,
            publisherRepository: publisherRepository,
            pluginRegistry: pluginRegistry,
            statsCollector: statsCollector
        )

        _ = try await sut.createSession(for: "a-room")

        #expect(sut.currentCall != nil)

        sut.clearSession()

        #expect(sut.currentCall == nil)
    }

    // MARK: - Test Helpers

    private func makeSUT<Provider: SessionProvider>(
        sessionProvider: Provider,
        publisherRepository: PublisherRepository,
        pluginRegistry: VonagePluginRegistry,
        statsCollector: StatsCollector
    ) -> VonageSessionRepository<Provider> where Provider.Session == VonageSession {
        VonageSessionRepository(
            sessionProvider: sessionProvider,
            publisherRepository: publisherRepository,
            pluginRegistry: pluginRegistry,
            statsCollector: statsCollector
        )
    }
}
