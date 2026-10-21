//
//  Created by Vonage on 27/9/26.
//

import Foundation
import Testing
import VERACore
import VERADomain
import VERATestHelpers

@testable import VERAVonage

@Suite("VonageSessionProvider tests")
struct VonageSessionProviderTests {

    @Test
    func makeSessionResolvesCredentialsBuildsSessionAndWritesSessionKey() async throws {
        let factory = MockVonageSessionFactory()
        let sessionKeyHolder = DefaultSessionKeyHolder()
        let sut = VonageSessionProvider(
            sessionFactory: factory,
            roomCredentialsRepository: makeMockRoomCredentialsRepository(
                .init(sessionId: "s", token: "t", apiKey: "a", sessionKey: "the-session-key")),
            sessionKeyWriter: sessionKeyHolder)

        _ = try await sut.makeSession(for: "a-room")

        #expect(factory.makeCalled)
        #expect(sessionKeyHolder.sessionKey == "the-session-key")
    }

    @Test
    func makeSessionPropagatesFactoryError() async {
        let factory = ThrowingSessionFactory()
        let sut = VonageSessionProvider(
            sessionFactory: factory,
            roomCredentialsRepository: makeMockRoomCredentialsRepository(),
            sessionKeyWriter: DefaultSessionKeyHolder())

        await #expect(throws: ThrowingSessionFactory.Error.self) {
            _ = try await sut.makeSession(for: "a-room")
        }
    }
}

private final class ThrowingSessionFactory: SessionFactory {
    enum Error: Swift.Error {
        case any
    }

    typealias Session = VonageSession

    func make(_ credentials: RoomCredentials) throws -> VonageSession {
        throw Error.any
    }
}
