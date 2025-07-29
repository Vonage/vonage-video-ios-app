//
//  Created by Vonage on 28/7/25.
//

import Foundation
import OpenTok
import Testing
import VERACore
import VERAOpenTok

@Suite("OpenTok Call tests")
struct OpenTokCallTests {

    @Test
    func connectCallsSessionConnectWithAnSpecificToken() async throws {
        let aToken = "random-token"
        let session = OpenTokSessionSpy()
        let sut = makeSUT(token: aToken, session: session)

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
            Issue.record("Expected error event, got: \(event)")
        }
    }

    @Test
    func disconnectCallsSessionDisconnect() async throws {
        let session = OpenTokSessionSpy()
        let sut = makeSUT(session: session)

        #expect(session.disconnectCalled == false)
        sut.disconnect()
        #expect(session.disconnectCalled == true)
    }

    @Test
    func disconnectPublishesErrorWhenSessionThrows() async throws {
        let session = ThrowingOpenTokSession()
        let sut = makeSUT(session: session)

        sut.disconnect()

        let event = await sut.eventsPublisher.values.first { event in
            if case .error = event { return true }
            return false
        }

        switch event {
        case .error(let error):
            #expect(error is ThrowingOpenTokSession.Error)
        default:
            Issue.record("Expected error event, got: \(event)")
        }
    }

    // MARK: - Test Helpers

    private func makeSUT(
        token: String = "a token",
        session: OpenTokSession = OpenTokSessionSpy()
    ) -> OpenTokCall {
        return OpenTokCall(token: token, session: session)
    }
}


class OpenTokSessionSpy: OpenTokSession {
    var connectCalled = false
    var disconnectCalled = false

    var recordedTokens: [String] = []

    init() {
        super.init(
            session: OTSession(
                applicationId: "applicationId",
                sessionId: "sessionId",
                delegate: nil)!)
    }

    public override func connect(with token: String) throws {
        connectCalled = true
        recordedTokens.append(token)
        try super.connect(with: token)
    }

    public override func disconnect() throws {
        disconnectCalled = true
        try super.disconnect()
    }
}

class ThrowingOpenTokSession: OpenTokSession {

    enum Error: Swift.Error {
        case any
    }

    init() {
        super.init(
            session: OTSession(
                applicationId: "applicationId",
                sessionId: "sessionId",
                delegate: nil)!)
    }

    public override func connect(with token: String) throws {
        throw Error.any
    }

    public override func disconnect() throws {
        throw Error.any
    }
}
