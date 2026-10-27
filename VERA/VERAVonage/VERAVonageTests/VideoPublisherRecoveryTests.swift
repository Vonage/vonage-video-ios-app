import Combine
import Foundation
import OpenTok
import Testing
import VERADomain
import VERATestHelpers

@testable import VERAVonage

@Suite("Serialized publisher recovery", .serialized)
@MainActor
struct VideoPublisherRecoveryTests {
    @Test func recreatesAfterWebRTCFailureAndPreservesMuteCameraAndSettings() async throws {
        let session = PublisherRecoverySession()
        let repository = RecoveryPublisherRepository()
        let original = VonagePublisherSpy()
        original.publishAudio = false
        original.cameraPosition = .back
        original.recoverySettings = .init(videoResolution: .high)
        let call = makeCall(session: session, repository: repository, publisher: original)
        call.publisherRecovery.wait = { _ in }
        try await call.connect()
        session.onSessionDidConnect?()
        let staleError = original.onError
        original.onError?(transient())
        original.onError?(transient())
        await settle()
        #expect(repository.settings.count == 1)
        #expect(repository.settings.first?.publishAudio == false)
        #expect(repository.settings.first?.advancedSettings?.videoResolution == .high)
        #expect(call.publisher !== original)
        #expect(call.publisher.cameraPosition == .back)
        #expect(original.cleanUpCallCount == 1)
        #expect(session.unpublishCount == 1)
        staleError?(transient())
        await settle()
        #expect(repository.settings.count == 1)
        try await call.disconnect()
    }

    @Test func synchronousPublishFailuresStopAfterThreeTotalAttempts() async throws {
        let session = PublisherRecoverySession()
        session.publishFailure = transient()
        let repository = RecoveryPublisherRepository()
        let call = makeCall(session: session, repository: repository)
        call.publisherRecovery.wait = { _ in }
        var failures = 0
        let observation = call.eventsPublisher.sink { if case .error = $0 { failures += 1 } }
        defer { observation.cancel() }
        try await call.connect()
        session.onSessionDidConnect?()
        await settle()
        #expect(session.publishCount == 3)
        #expect(repository.settings.count == 2)
        #expect(failures == 1)
        try await call.disconnect()
    }

    @Test func successfulPublisherCountsTowardLaterRecoveryBudget() async throws {
        let session = PublisherRecoverySession()
        let repository = RecoveryPublisherRepository()
        let call = makeCall(session: session, repository: repository)
        call.publisherRecovery.wait = { _ in }
        try await call.connect()
        session.onSessionDidConnect?()
        await settle()
        call.publisher.onStreamCreated?()
        await settle()
        session.publishFailure = transient()
        call.publisher.onError?(transient())
        await settle()
        #expect(session.publishCount == 3)
        #expect(repository.settings.count == 2)
        try await call.disconnect()
    }

    @Test func unknownFailureIsReportedWithoutReplacement() async throws {
        let session = PublisherRecoverySession()
        let repository = RecoveryPublisherRepository()
        let call = makeCall(session: session, repository: repository)
        var failures = 0
        let observation = call.eventsPublisher.sink { if case .error = $0 { failures += 1 } }
        defer { observation.cancel() }
        try await call.connect()
        session.onSessionDidConnect?()
        call.publisher.onError?(NSError(domain: "OTPublisherErrorDomain", code: 6006))
        await settle()
        #expect(repository.settings.isEmpty)
        #expect(failures == 1)
        try await call.disconnect()
    }

    @Test func hangupCancelsDelayedReplacement() async throws {
        let session = PublisherRecoverySession()
        let repository = RecoveryPublisherRepository()
        let call = makeCall(session: session, repository: repository)
        try await call.connect()
        session.onSessionDidConnect?()
        call.publisher.onError?(transient())
        await settle()
        try await call.disconnect()
        #expect(repository.settings.isEmpty)
    }

    @Test func sdkReconnectDoesNotStartApplicationPublisherReplacement() async throws {
        let session = PublisherRecoverySession()
        let repository = RecoveryPublisherRepository()
        let call = makeCall(session: session, repository: repository)
        try await call.connect()
        session.onSessionDidConnect?()
        session.onSessionDidBeginReconnecting?()
        call.publisher.onError?(transient())
        await settle()
        #expect(repository.settings.isEmpty)
        try await call.disconnect()
    }

    @Test func recoveryQueuedBehindSettingsDoesNotReplaceTheNewPublisherAgain() async throws {
        let session = PublisherRecoverySession()
        let repository = RecoveryPublisherRepository()
        let call = makeCall(session: session, repository: repository)
        call.publisherRecovery.wait = { _ in }
        var resume: CheckedContinuation<Void, Never>?
        call.publisherReplacementSuspension = { await withCheckedContinuation { resume = $0 } }
        try await call.connect()
        session.onSessionDidConnect?()
        let oldError = call.publisher.onError
        let settings = Task { @MainActor in
            try await call.applyPublisherAdvancedSettings(.init(videoResolution: .high))
        }
        await settle()
        call.publisher.publishAudio = false
        oldError?(transient())
        await settle()
        resume?.resume()
        try await settings.value
        await settle()
        #expect(repository.settings.count == 1)
        #expect(session.unpublishCount == 1)
        #expect(repository.settings.first?.publishAudio == false)
        try await call.disconnect()
    }

    @Test func heldPublisherIsNotAutomaticallyRecreated() async throws {
        let session = PublisherRecoverySession()
        let repository = RecoveryPublisherRepository()
        let call = makeCall(session: session, repository: repository)
        try await call.connect()
        session.onSessionDidConnect?()
        call.publisher.setOnHold(true)
        call.publisher.onError?(transient())
        await settle()
        #expect(repository.settings.isEmpty)
        try await call.disconnect()
    }

    @Test func permanentFailureCancelsAlreadyScheduledRecovery() async throws {
        let session = PublisherRecoverySession()
        let repository = RecoveryPublisherRepository()
        let call = makeCall(session: session, repository: repository)
        var resume: CheckedContinuation<Void, Never>?
        call.publisherRecovery.wait = { _ in await withCheckedContinuation { resume = $0 } }
        try await call.connect()
        session.onSessionDidConnect?()
        call.publisher.onError?(transient())
        await settle()
        let pendingWait = try #require(resume)
        call.publisher.onError?(NSError(domain: "OTPublisherErrorDomain", code: 6006))
        await settle()
        pendingWait.resume()
        await settle()
        #expect(repository.settings.isEmpty)
        try await call.disconnect()
    }

    private func makeCall(
        session: PublisherRecoverySession, repository: RecoveryPublisherRepository,
        publisher: VonagePublisher = VonagePublisherSpy()
    ) -> VonageCall {
        VonageCall(
            roomName: makeMockCredentials().roomName, makeSession: { _ in session },
            publisher: publisher, publisherRepository: repository, statsCollector: MockStatsCollector())
    }

    private func transient() -> NSError { NSError(domain: "OTPublisherErrorDomain", code: 1610) }
    private func settle() async { for _ in 0..<200 { await Task.yield() } }
}

private final class PublisherRecoverySession: VonageSession {
    var publishCount = 0
    var unpublishCount = 0
    var publishFailure: NSError?

    init() {
        super.init(
            session: OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!,
            credentials: makeMockCredentials())
    }

    override func connect() throws {}
    override func disconnect() throws {}
    override func publish(publisher: VonagePublisher) throws {
        publishCount += 1
        if let publishFailure { throw publishFailure }
    }
    override func unpublish(publisher: VonagePublisher) throws { unpublishCount += 1 }
}

private final class RecoveryPublisherRepository: PublisherRepository {
    var settings: [PublisherSettings] = []
    private var publisher: VonagePublisher = VonagePublisherSpy()
    func getPublisher() -> any VERAPublisher { publisher }
    func resetPublisher() { publisher.cleanUp() }
    func recreatePublisher(_ settings: PublisherSettings) throws {
        self.settings.append(settings)
        publisher = VonagePublisherSpy()
        publisher.publishAudio = settings.publishAudio
        publisher.publishVideo = settings.publishVideo
    }
}
