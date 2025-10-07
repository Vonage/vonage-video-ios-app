//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import Testing
import VERACore
import VERAOpenTok
import VERATestHelpers

@MainActor
@Suite("OpenTokSessionRepository tests")
struct OpenTokSessionRepositoryTests {

    @Test
    func createsSessionSuccessfully() async throws {
        let sessionFactory = MockOpenTokSessionFactory()
        let publisherRepository = MockPublisherRepository()
        let sut = makeSUT(sessionFactory: sessionFactory, publisherRepository: publisherRepository)
        let credentials = makeMockCredentials()
        _ = sut.createSession(credentials)

        #expect(sessionFactory.makeCalled)
    }

    @Test
    func clearsSessionSuccessfully() async throws {
        let sessionFactory = MockOpenTokSessionFactory()
        let publisherRepository = MockPublisherRepository()
        let sut = makeSUT(sessionFactory: sessionFactory, publisherRepository: publisherRepository)
        let credentials = makeMockCredentials()
        _ = sut.createSession(credentials)

        #expect(sut.currentCall != nil)

        sut.clearSession()

        #expect(sut.currentCall == nil)
    }

    // MARK: - Test Helpers

    private func makeSUT<Factory: SessionFactory>(
        sessionFactory: Factory,
        publisherRepository: PublisherRepository
    ) -> OpenTokSessionRepository<Factory> where Factory.Session == OpenTokSession {
        OpenTokSessionRepository(
            sessionFactory: sessionFactory,
            publisherRepository: publisherRepository)
    }
}
