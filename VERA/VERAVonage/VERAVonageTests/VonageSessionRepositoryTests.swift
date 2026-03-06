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
        let sessionFactory = MockVonageSessionFactory()
        let publisherRepository = MockPublisherRepository()
        let pluginRegistry = VonagePluginRegistry()
        let statsCollector = MockStatsCollector()

        let sut = makeSUT(
            sessionFactory: sessionFactory,
            publisherRepository: publisherRepository,
            pluginRegistry: pluginRegistry,
            statsCollector: statsCollector
        )

        let credentials = makeMockCredentials()
        _ = try sut.createSession(credentials)

        #expect(sessionFactory.makeCalled)
    }

    @Test
    func clearsSessionSuccessfully() async throws {
        let sessionFactory = MockVonageSessionFactory()
        let publisherRepository = MockPublisherRepository()
        let pluginRegistry = VonagePluginRegistry()
        let statsCollector = MockStatsCollector()

        let sut = makeSUT(
            sessionFactory: sessionFactory,
            publisherRepository: publisherRepository,
            pluginRegistry: pluginRegistry,
            statsCollector: statsCollector
        )

        let credentials = makeMockCredentials()
        _ = try sut.createSession(credentials)

        #expect(sut.currentCall != nil)

        sut.clearSession()

        #expect(sut.currentCall == nil)
    }

    // MARK: - Test Helpers

    private func makeSUT<Factory: SessionFactory>(
        sessionFactory: Factory,
        publisherRepository: PublisherRepository,
        pluginRegistry: VonagePluginRegistry,
        statsCollector: StatsCollector
    ) -> VonageSessionRepository<Factory> where Factory.Session == VonageSession {
        VonageSessionRepository(
            sessionFactory: sessionFactory,
            publisherRepository: publisherRepository,
            pluginRegistry: pluginRegistry,
            statsCollector: statsCollector
        )
    }
}
