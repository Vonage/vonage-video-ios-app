import Combine
import Foundation
import OpenTok
import Testing
import VERADomain
import VERATestHelpers

@testable import VERAVonage

@Suite("Call subscription recovery", .serialized)
@MainActor
struct VonageCallSubscriptionRecoveryTests {
    @Test func availableStreamReportsSubscriberCreationFailureOnce() async throws {
        let harness = try await connectedHarness()
        let stream = OTStream()
        harness.session.presentIDs = [stream.streamId]
        harness.session.onNewStream?(stream)
        harness.session.onNewStream?(stream)
        await settle()

        #expect(harness.session.hasStreamCalls >= 1)
        #expect(harness.errors.count == 1)
        #expect(harness.errors.first is VonageSubscriberFactory.Error)
        #expect(await harness.call.subscriber(for: stream.streamId) == nil)
        try await harness.call.disconnect()
    }

    @Test func missingStreamIsNotACallError() async throws {
        let harness = try await connectedHarness()
        harness.session.onNewStream?(OTStream())
        await settle()
        #expect(harness.session.hasStreamCalls >= 1)
        #expect(harness.errors.isEmpty)
        try await harness.call.disconnect()
    }

    @Test func reconnectWaitsUntilTheSessionIsConnectedAgain() async throws {
        let harness = try await connectedHarness()
        let stream = OTStream()
        harness.session.presentIDs = [stream.streamId]
        harness.session.remoteStreams = [stream]
        harness.session.onSessionDidBeginReconnecting?()
        harness.session.onNewStream?(stream)
        await settle()
        #expect(harness.errors.isEmpty)

        harness.session.onSessionDidReconnect?()
        await settle()
        #expect(harness.errors.count == 1)
        #expect(harness.errors.first is VonageSubscriberFactory.Error)
        try await harness.call.disconnect()
    }

    @Test func hangupIgnoresAStreamThatArrivesAfterwards() async throws {
        let harness = try await connectedHarness()
        try await harness.call.disconnect()
        let stream = OTStream()
        harness.session.presentIDs = [stream.streamId]
        harness.session.onNewStream?(stream)
        await settle()
        #expect(harness.errors.isEmpty)
    }

    @Test func destroyingAStreamDoesNotReportAnotherError() async throws {
        let harness = try await connectedHarness()
        let stream = OTStream()
        harness.session.presentIDs = [stream.streamId]
        harness.session.onNewStream?(stream)
        await settle()
        harness.session.onStreamDestroyed?(stream)
        await settle()
        #expect(harness.errors.count == 1)
        try await harness.call.disconnect()
    }

    @Test func nativeSessionWithoutStreamsReportsNonePresent() throws {
        let session = VonageSession(
            session: OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!,
            credentials: makeMockCredentials())
        #expect(session.hasStream("missing") == false)
        #expect(session.availableRemoteStreams.isEmpty)
    }

    private func connectedHarness() async throws -> Harness {
        let session = SubscriptionSession()
        let call = VonageCall(
            roomName: makeMockCredentials().roomName, makeSession: { _ in session },
            publisher: VonagePublisherSpy(), publisherRepository: MockPublisherRepository(),
            statsCollector: MockStatsCollector())
        let harness = Harness(call: call, session: session)
        call.subscriptionRecovery.wait = { _ in }
        try await call.connect()
        session.onSessionDidConnect?()
        await settle()
        return harness
    }

    private func settle() async { for _ in 0..<200 { await Task.yield() } }

    private final class Harness {
        let call: VonageCall
        let session: SubscriptionSession
        var errors: [Error] = []
        private var observation: AnyCancellable?

        init(call: VonageCall, session: SubscriptionSession) {
            self.call = call
            self.session = session
            observation = call.eventsPublisher.sink { [weak self] event in
                if case .error(let error) = event { self?.errors.append(error) }
            }
        }
    }
}

private final class SubscriptionSession: VonageSession {
    var presentIDs: Set<String> = []
    var remoteStreams: [OTStream] = []
    var hasStreamCalls = 0

    init() {
        super.init(
            session: OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!,
            credentials: makeMockCredentials())
    }

    override func connect() throws {}
    override func disconnect() throws {}
    override func publish(publisher: VonagePublisher) throws {}
    override func unpublish(publisher: VonagePublisher) throws {}
    override func hasStream(_ streamID: String) -> Bool {
        hasStreamCalls += 1
        return presentIDs.contains(streamID)
    }
    override var availableRemoteStreams: [OTStream] { remoteStreams }
}
