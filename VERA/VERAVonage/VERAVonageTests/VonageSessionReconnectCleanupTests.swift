//
//  Created by Vonage on 15/10/26.
//

import OpenTok
import Testing
import VERADomain

@testable import VERAVonage

@MainActor
@Suite("Session reconnect callback cleanup")
struct VonageSessionReconnectCleanupTests {
    @Test("Reconnect callbacks stop after repeated cleanup", arguments: [false, true])
    func cleanupStopsLateCallbacks(didReconnect: Bool) throws {
        let sut = try makeSUT()
        let session = try makeOTSession()
        var received = 0
        installCallback(on: sut, didReconnect: didReconnect) { received += 1 }

        emitCallback(on: sut, session: session, didReconnect: didReconnect)
        #expect(received == 1)

        sut.cleanUp()
        sut.cleanUp()
        emitCallback(on: sut, session: session, didReconnect: didReconnect)
        #expect(received == 1)
    }

    @Test("Cleanup releases callback captures while the session wrapper stays alive", arguments: [false, true])
    func cleanupReleasesCallbackCaptures(didReconnect: Bool) throws {
        let sut = try makeSUT()
        weak var releasedObserver: ReconnectObserver?
        do {
            let observer = ReconnectObserver()
            releasedObserver = observer
            installCallback(on: sut, didReconnect: didReconnect) { observer.receive() }
        }
        #expect(releasedObserver != nil)

        sut.cleanUp()

        withExtendedLifetime(sut) {
            #expect(releasedObserver == nil)
        }
    }

    @Test("Cleaning an old wrapper keeps a separate live session's callbacks active", arguments: [false, true])
    func cleanupDoesNotSilenceAnotherSession(didReconnect: Bool) throws {
        let oldSession = try makeSUT()
        let liveSession = try makeSUT()
        let session = try makeOTSession()
        var oldEvents = 0
        var liveEvents = 0
        installCallback(on: oldSession, didReconnect: didReconnect) { oldEvents += 1 }
        installCallback(on: liveSession, didReconnect: didReconnect) { liveEvents += 1 }
        emitCallback(on: oldSession, session: session, didReconnect: didReconnect)
        emitCallback(on: liveSession, session: session, didReconnect: didReconnect)

        oldSession.cleanUp()
        emitCallback(on: oldSession, session: session, didReconnect: didReconnect)
        emitCallback(on: liveSession, session: session, didReconnect: didReconnect)

        #expect(oldEvents == 1)
        #expect(liveEvents == 2)
    }

    private func installCallback(on sut: VonageSession, didReconnect: Bool, callback: @escaping () -> Void) {
        if didReconnect {
            sut.onSessionDidReconnect = callback
        } else {
            sut.onSessionDidBeginReconnecting = callback
        }
    }

    private func emitCallback(on sut: VonageSession, session: OTSession, didReconnect: Bool) {
        if didReconnect {
            sut.sessionDidReconnect(session)
        } else {
            sut.sessionDidBeginReconnecting(session)
        }
    }

    private func makeSUT() throws -> VonageSession {
        VonageSession(
            session: try makeOTSession(),
            credentials: RoomCredentials(
                sessionId: "sessionId",
                token: "token",
                applicationId: "applicationId",
                roomName: "roomName",
                sessionKey: "sessionKey"
            )
        )
    }

    private func makeOTSession() throws -> OTSession {
        try #require(OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil))
    }
}

private final class ReconnectObserver {
    private(set) var received = 0
    func receive() { received += 1 }
}
