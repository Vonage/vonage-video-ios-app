//
//  Created by Vonage on 28/7/25.
//

import Foundation
import OpenTok
import Testing
import VERACore
import VERAOpenTok
import VERATestHelpers

@Suite("OpenTok Call tests")
@MainActor
struct OpenTokCallTests {

    @Test
    func connectCallsSessionConnectWithAnSpecificToken() async throws {
        let aToken = "random-token"
        let session = OpenTokSessionSpy()
        let sut = makeSUT(
            credentials: makeMockCredentials(
                token: aToken
            ), session: session)

        #expect(session.connectCalled == false)
        #expect(session.recordedTokens.isEmpty)
        sut.connect()
        #expect(session.connectCalled == true)
        #expect(session.recordedTokens == [aToken])
    }

    @Test
    func connectPublishesErrorWhenSessionThrows() async throws {
        let session = ThrowingOpenTokSession()
        let sut = makeSUT(session: session)

        sut.connect()

        let event = await sut.eventsPublisher.values.first { event in
            if case .error = event { return true }
            return false
        }

        switch event {
        case .error(let error):
            #expect(error is ThrowingOpenTokSession.Error)
        default:
            Issue.record("Expected error event, got: \(String(describing: event))")
        }
    }

    @Test
    func disconnectPublishesErrorWhenSessionThrows() async throws {
        let session = ThrowingOpenTokSession()
        let sut = makeSUT(session: session)

        try? await sut.disconnect()

        let event = await sut.eventsPublisher.values.first { event in
            if case .error = event { return true }
            return false
        }

        switch event {
        case .error: break
        // Should be an error
        default:
            Issue.record("Expected error event, got: \(String(describing: event))")
        }
    }

    // MARK: - Test Helpers

    private func makeSUT(
        credentials: RoomCredentials = makeMockCredentials(),
        session: OpenTokSession = OpenTokSessionSpy(),
        publisher: OpenTokPublisher = OpenTokPublisherSpy()
    ) -> OpenTokCall {
        OpenTokCall(credentials: credentials, session: session, publisher: publisher)
    }
}
