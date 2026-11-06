import Combine
import Foundation
import OpenTok
import Testing
import VERADomain
import VERATestHelpers

@testable import VERAVonage

@Suite("Bounded initial connection recovery", .serialized)
@MainActor
struct VideoConnectionRecoveryTests {
    @Test func retriesSynchronousFailuresWithFreshSessionsAndIncreasingDelays() async throws {
        let sessions = [
            RecoverySession(failure: transient()), RecoverySession(failure: transient()), RecoverySession(),
        ]
        var created = 0
        var delays: [UInt64] = []
        let call = makeCall {
            defer { created += 1 }
            return sessions[created]
        }
        call.connectionRecovery.wait = { delays.append($0) }
        try await call.connect()
        await settle()
        #expect(created == 3)
        #expect(delays == [3_000_000_000, 6_000_000_000])
        #expect(sessions[0].disconnectCount == 1)
        #expect(sessions[1].disconnectCount == 1)
        #expect(sessions[0].onSessionDidConnect == nil)
        #expect(call.session === sessions[2])
        try await call.disconnect()
    }

    @Test func retriesDelegateFailureAndIgnoresOldCallbacks() async throws {
        let first = RecoverySession()
        let second = RecoverySession()
        var created = 0
        let call = makeCall {
            created += 1
            return created == 1 ? first : second
        }
        call.connectionRecovery.wait = { _ in }
        try await call.connect()
        let oldConnected = first.onSessionDidConnect
        first.onSessionFailure?(transient())
        await settle()
        oldConnected?()
        #expect(created == 2)
        #expect(second.publishCount == 0)
        second.onSessionDidConnect?()
        #expect(second.publishCount == 1)
        try await call.disconnect()
    }

    @Test func delegateFailureFollowedByDisconnectStillRetriesInitialJoin() async throws {
        let first = RecoverySession()
        let second = RecoverySession()
        var created = 0
        let call = makeCall {
            created += 1
            return created == 1 ? first : second
        }
        call.connectionRecovery.wait = { _ in }
        try await call.connect()
        first.onSessionFailure?(transient())
        first.onSessionDidDisconnect?()
        await settle()
        #expect(created == 2)
        #expect(call.session === second)
        try await call.disconnect()
    }

    @Test func stopsAfterThreeAttemptsAndForwardsTerminalFailure() async throws {
        var created = 0
        var errors = 0
        let call = makeCall {
            created += 1
            return RecoverySession(failure: transient())
        }
        let observation = call.eventsPublisher.sink { if case .sessionFailure = $0 { errors += 1 } }
        defer { observation.cancel() }
        call.connectionRecovery.wait = { _ in }
        try await call.connect()
        await settle()
        #expect(created == 3)
        #expect(errors == 1)
        #expect(call.session?.onSessionDidConnect == nil)
    }

    @Test func doesNotRetryAuthorizationOrUnknownErrors() async {
        for error in [NSError(domain: "OTSessionErrorDomain", code: 1004), NSError(domain: "other", code: 1021)] {
            var created = 0
            let call = makeCall {
                created += 1
                return RecoverySession(failure: error)
            }
            await #expect(throws: NSError.self) { try await call.connect() }
            #expect(created == 1)
        }
    }

    @Test func hangupCancelsPendingRetryEvenWhenWaitIgnoresCancellation() async throws {
        let gate = RecoveryGate()
        var created = 0
        let call = makeCall {
            created += 1
            return RecoverySession(failure: transient())
        }
        call.connectionRecovery.wait = { _ in await gate.wait() }
        try await call.connect()
        await settle()
        try await call.disconnect()
        gate.resume()
        await settle()
        #expect(created == 1)
    }

    @Test func connectedSessionFailureUsesTerminalCleanupNotInitialJoinRetries() async throws {
        let session = RecoverySession()
        var created = 0
        let call = makeCall {
            created += 1
            return session
        }
        try await call.connect()
        session.onSessionDidConnect?()
        session.onSessionFailure?(transient())
        await settle()
        #expect(created == 1)
        #expect(session.disconnectCount == 1)
    }

    private func makeCall(makeSession: @escaping () -> VonageSession) -> VonageCall {
        VonageCall(
            roomName: makeMockCredentials().roomName, makeSession: { _ in makeSession() },
            publisher: VonagePublisherSpy(), publisherRepository: MockPublisherRepository(),
            statsCollector: MockStatsCollector())
    }

    private func transient() -> NSError { NSError(domain: "OTSessionErrorDomain", code: 1021) }
    private func settle() async { for _ in 0..<100 { await Task.yield() } }
}

private final class RecoverySession: VonageSession {
    let failure: NSError?
    var disconnectCount = 0
    var publishCount = 0

    init(failure: NSError? = nil) {
        self.failure = failure
        super.init(
            session: OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!,
            credentials: makeMockCredentials())
    }

    override func connect() throws { if let failure { throw failure } }
    override func disconnect() throws { disconnectCount += 1 }
    override func publish(publisher: VonagePublisher) throws { publishCount += 1 }
}

@MainActor
private final class RecoveryGate {
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { await withCheckedContinuation { continuation = $0 } }
    func resume() {
        continuation?.resume()
        continuation = nil
    }
}
