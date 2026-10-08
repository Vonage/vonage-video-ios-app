//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import OpenTok
import Testing
import VERACore
import VERADomain
import VERATestHelpers

@testable import VERAVonage

@Suite("Vonage Call tests")
@MainActor
struct VonageCallTests {

    @Test
    func connectCallsSessionConnectWithAnSpecificToken() async throws {
        let aToken = "random-token"
        let session = VonageSessionSpy(token: aToken)
        let sut = makeSUT(
            credentials: makeMockCredentials(
                token: aToken
            ), session: session)
        sut.setup()

        #expect(session.connectCalled == false)
        #expect(session.recordedTokens.isEmpty)
        try await sut.connect()
        #expect(session.connectCalled == true)
        #expect(session.recordedTokens == [aToken])
    }

    @Test
    func connectPublishesErrorWhenSessionThrows() async throws {
        let session = ThrowingVonageSession()
        let sut = makeSUT(session: session)
        sut.setup()

        await #expect(throws: ThrowingVonageSession.Error.self) { try await sut.connect() }

        let event = await sut.eventsPublisher.values.first { event in
            if case .error = event { return true }
            return false
        }

        switch event {
        case .error(let error):
            #expect(error is ThrowingVonageSession.Error)
        default:
            Issue.record("Expected error event, got: \(String(describing: event))")
        }
    }

    @Test
    func disconnectPublishesErrorWhenSessionThrows() async throws {
        let session = DisconnectFailureSession()
        let sut = makeSUT(session: session)
        var errors: [Swift.Error] = []
        var state: CallState = .idle
        let events = sut.eventsPublisher.sink { if case .error(let error) = $0 { errors.append(error) } }
        let states = sut.callState.sink { state = $0 }
        defer {
            events.cancel()
            states.cancel()
        }
        sut.setup()
        try await sut.connect()
        session.onSessionDidConnect?()
        await #expect(throws: ThrowingVonageSession.Error.self) { try await sut.disconnect() }
        #expect(errors.last is ThrowingVonageSession.Error)
        #expect(state == .disconnected)
        #expect(session.onSessionDidConnect == nil)
    }

    @Test
    func connectRethrowsAndDisconnectsWhenSessionCreationFails() async throws {
        enum MakeSessionError: Swift.Error { case failed }
        let publisherRepository = MockPublisherRepository()
        let sut = VonageCall(
            roomName: makeMockCredentials().roomName,
            makeSession: { _ in throw MakeSessionError.failed },
            publisher: VonagePublisherSpy(),
            publisherRepository: publisherRepository,
            statsCollector: MockStatsCollector()
        )
        sut.setup()

        await #expect(throws: MakeSessionError.self) {
            try await sut.connect()
        }

        let state = await sut.callState.values.first { $0 == .disconnected }
        #expect(state == .disconnected)
    }

    // MARK: - Participant moderation tests

    @Test
    func forceMuteParticipantThrowsWhenParticipantDoesNotExist() async {
        let sut = makeSUT()

        await #expect(throws: ParticipantForceMuteError.participantNotFound) {
            try await sut.forceMuteParticipant(id: "missing-participant")
        }
        #expect(
            ParticipantForceMuteError.participantNotFound.localizedDescription
                == "The participant is no longer in the call."
        )
    }

    @Test
    func forceMuteParticipantForwardsResolvedStreamToSession() async throws {
        let stream = makeOpaqueStream()
        let session = VonageSessionSpy()
        let sut = makeSUT(session: session)
        sut.setup()
        try await sut.connect()
        sut.participantStreamResolver = { id in
            #expect(id == "participant-id")
            return stream
        }

        try await sut.forceMuteParticipant(id: "participant-id")

        #expect(session.forceMutedStreams.count == 1)
        #expect(session.forceMutedStreams.first === stream)
    }

    @Test
    func forceMuteParticipantPropagatesSessionError() async throws {
        let stream = makeOpaqueStream()
        let session = VonageSessionSpy()
        session.forceMuteError = ForceMuteTestError.requestFailed
        let sut = makeSUT(session: session)
        sut.setup()
        try await sut.connect()
        sut.participantStreamResolver = { _ in stream }

        await #expect(throws: ForceMuteTestError.requestFailed) {
            try await sut.forceMuteParticipant(id: "participant-id")
        }
    }

    @Test
    func forceMuteSessionSucceedsWhenOperationReturnsNoError() throws {
        let stream = makeOpaqueStream()
        let sut = makeBaseSession()
        sut.forceMuteStreamOperation = { receivedStream in
            #expect(receivedStream === stream)
            return nil
        }

        try sut.forceMute(stream: stream)
    }

    @Test
    func forceMuteSessionThrowsOperationError() {
        let stream = makeOpaqueStream()
        let expectedError = OTError(
            domain: OT_SESSION_ERROR_DOMAIN,
            code: 1540,
            userInfo: nil
        )
        let sut = makeBaseSession()
        sut.forceMuteStreamOperation = { _ in expectedError }

        #expect(throws: OTError.self) {
            try sut.forceMute(stream: stream)
        }
    }

    @Test
    func publisherMuteForcedUpdatesLocalStateAndPublishesEvent() async throws {
        let publisherSpy = VonagePublisherSpy()
        let sut = makeSUT(publisher: publisherSpy)
        sut.setup()
        try await sut.connect()

        publisherSpy.muteForced(publisherSpy.exposedOTPublisher)

        let state = await sut.statePublisher.values.first { !$0.isPublishingAudio }
        let event = await sut.eventsPublisher.values.first { event in
            if case .muteForced = event { return true }
            return false
        }

        #expect(publisherSpy.publishAudio == false)
        #expect(state?.isPublishingAudio == false)
        if case .muteForced = event {
            #expect(true)
        } else {
            Issue.record("Expected muteForced event")
        }
    }

    // MARK: - Network Stats Tests

    @Test
    func enableNetworkStats_setsPublisherDelegateAndRequestsStats() async throws {
        let publisherSpy = VonagePublisherSpy()
        let statsCollector = MockStatsCollector()
        let sut = makeSUT(publisher: publisherSpy, statsCollector: statsCollector)
        sut.setup()

        sut.enableNetworkStats()

        #expect(publisherSpy.exposedOTPublisher.networkStatsDelegate === statsCollector)
        #expect(statsCollector.requestRtcStatsFromPublisherCallCount == 1)
        #expect(statsCollector.publishersRequested.first === publisherSpy.exposedOTPublisher)
    }

    @Test
    func enableNetworkStats_isIdempotent() async throws {
        let publisherSpy = VonagePublisherSpy()
        let statsCollector = MockStatsCollector()
        let sut = makeSUT(publisher: publisherSpy, statsCollector: statsCollector)
        sut.setup()

        sut.enableNetworkStats()
        sut.enableNetworkStats()

        #expect(statsCollector.requestRtcStatsFromPublisherCallCount == 1)
    }

    @Test
    func disableNetworkStats_clearsDelegateAndResetsCollector() async throws {
        let publisherSpy = VonagePublisherSpy()
        let statsCollector = MockStatsCollector()
        let sut = makeSUT(publisher: publisherSpy, statsCollector: statsCollector)

        sut.enableNetworkStats()
        sut.disableNetworkStats()

        #expect(publisherSpy.exposedOTPublisher.networkStatsDelegate == nil)
        #expect(publisherSpy.exposedOTPublisher.rtcStatsReportDelegate == nil)
        #expect(statsCollector.resetCallCount == 1)
    }

    @Test
    func disableNetworkStats_isIdempotent() async throws {
        let statsCollector = MockStatsCollector()
        let sut = makeSUT(statsCollector: statsCollector)
        sut.setup()

        sut.disableNetworkStats()
        sut.disableNetworkStats()

        #expect(statsCollector.resetCallCount == 0)
    }

    // MARK: - Publisher Settings Tests

    @Test
    func applyPublisherAdvancedSettings_returnsEarlyWhenNotConnected() async throws {
        let publisherRepository = MockPublisherRepository()
        let sut = makeSUT(publisherRepository: publisherRepository)
        sut.setup()

        let advancedSettings = PublisherAdvancedSettings(
            videoResolution: .high,
            videoFrameRate: .rate30FPS
        )

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(publisherRepository.recreatePublisherCallCount == 0)
    }

    @Test
    func applyPublisherAdvancedSettings_mergesSettingsPreservingRuntimeState() async throws {
        let publisherSpy = VonagePublisherSpy()
        publisherSpy.publishAudio = true
        publisherSpy.publishVideo = false

        let session = VonageSessionSpy()
        let publisherRepository = MockPublisherRepository()
        let sut = makeSUT(
            session: session,
            publisher: publisherSpy,
            publisherRepository: publisherRepository
        )
        sut.setup()

        // Connect to enable settings application
        try await sut.connect()

        let advancedSettings = PublisherAdvancedSettings(
            videoResolution: .high,
            videoFrameRate: .rate30FPS,
            maxAudioBitrate: 40000,
            opusDtxEnabled: true
        )

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(publisherRepository.recreatePublisherCallCount == 1)

        guard let recordedSettings = publisherRepository.recordedSettings.first else {
            Issue.record("Expected recorded settings")
            return
        }

        #expect(recordedSettings.publishAudio == true)
        #expect(recordedSettings.publishVideo == false)
        #expect(recordedSettings.advancedSettings?.videoResolution == .high)
        #expect(recordedSettings.advancedSettings?.videoFrameRate == .rate30FPS)
        #expect(recordedSettings.advancedSettings?.maxAudioBitrate == 40000)
        #expect(recordedSettings.advancedSettings?.opusDtxEnabled == true)
    }

    @Test
    func applyPublisherAdvancedSettings_unpublishesOldPublisher() async throws {
        let publisherSpy = VonagePublisherSpy()
        let session = VonageSessionSpy()
        let publisherRepository = MockPublisherRepository()
        let sut = makeSUT(
            session: session,
            publisher: publisherSpy,
            publisherRepository: publisherRepository
        )
        sut.setup()

        try await sut.connect()

        let advancedSettings = PublisherAdvancedSettings(videoResolution: .high)

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(session.unpublishCalled == true)
        #expect(session.unpublishedPublishers.first === publisherSpy)
    }

    @Test
    func applyPublisherAdvancedSettings_cleansUpOldPublisher() async throws {
        let publisherSpy = VonagePublisherSpy()
        let session = VonageSessionSpy()
        let publisherRepository = MockPublisherRepository()
        let sut = makeSUT(
            session: session,
            publisher: publisherSpy,
            publisherRepository: publisherRepository
        )
        sut.setup()

        try await sut.connect()

        let advancedSettings = PublisherAdvancedSettings(videoResolution: .high)

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(publisherSpy.cleanUpCallCount == 1)
    }

    @Test
    func applyPublisherAdvancedSettings_restoresNetworkStatsWhenEnabled() async throws {
        let publisherSpy = VonagePublisherSpy()
        let session = VonageSessionSpy()
        let statsCollector = MockStatsCollector()
        let newPublisherSpy = VonagePublisherSpy()
        let publisherRepository = MockPublisherRepository()
        publisherRepository.publisherToReturn = newPublisherSpy

        let sut = makeSUT(
            session: session,
            publisher: publisherSpy,
            publisherRepository: publisherRepository,
            statsCollector: statsCollector
        )
        sut.setup()

        try await sut.connect()
        sut.enableNetworkStats()

        let advancedSettings = PublisherAdvancedSettings(videoResolution: .high)

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(newPublisherSpy.exposedOTPublisher.networkStatsDelegate === statsCollector)
        #expect(statsCollector.requestRtcStatsFromPublisherCallCount >= 2)
    }

    @Test
    func applyPublisherAdvancedSettings_doesNotSetStatsWhenDisabled() async throws {
        let publisherSpy = VonagePublisherSpy()
        let session = VonageSessionSpy()
        let newPublisherSpy = VonagePublisherSpy()
        let publisherRepository = MockPublisherRepository()
        publisherRepository.publisherToReturn = newPublisherSpy

        let sut = makeSUT(
            session: session,
            publisher: publisherSpy,
            publisherRepository: publisherRepository
        )
        sut.setup()

        try await sut.connect()

        let advancedSettings = PublisherAdvancedSettings(videoResolution: .high)

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(newPublisherSpy.exposedOTPublisher.networkStatsDelegate == nil)
    }

    @Test
    func updateLivePublisherAdvancedSettings_updatesCurrentPublisherWithoutRecreation() async throws {
        let publisherSpy = VonagePublisherSpy()
        let session = VonageSessionSpy()
        let sut = makeSUT(
            session: session,
            publisher: publisherSpy
        )
        sut.setup()
        try await sut.connect()

        let advancedSettings = PublisherAdvancedSettings(
            videoBitratePreset: .customBitrate,
            maxVideoBitrate: 1_500_000,
            degradationPreference: .balanced
        )

        await sut.updateLivePublisherAdvancedSettings(advancedSettings)

        #expect(publisherSpy.exposedOTPublisher.videoBitratePreset == .custom)
        #expect(publisherSpy.exposedOTPublisher.maxVideoBitrate == 1_500_000)
        #expect(publisherSpy.exposedOTPublisher.degradationPreference == .balanced)
    }

    @Test
    func applyPublisherAdvancedSettings_restoresCameraPosition() async throws {
        let publisherSpy = VonagePublisherSpy()
        publisherSpy.cameraPosition = .back

        let session = VonageSessionSpy()
        let newPublisherSpy = VonagePublisherSpy()
        let publisherRepository = MockPublisherRepository()
        publisherRepository.publisherToReturn = newPublisherSpy

        let sut = makeSUT(
            session: session,
            publisher: publisherSpy,
            publisherRepository: publisherRepository
        )
        sut.setup()

        try await sut.connect()

        let advancedSettings = PublisherAdvancedSettings(videoResolution: .high)

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(newPublisherSpy.cameraPosition == .back)
    }

    @Test
    func applyPublisherAdvancedSettings_restoresVideoTransformers() async throws {
        let publisherSpy = VonagePublisherSpy()
        let transformer1 = MockTransformer(key: "blur", transformer: NSObject())
        let transformer2 = MockTransformer(key: "filter", transformer: NSObject())
        publisherSpy.setVideoTransformers([transformer1, transformer2])

        let session = VonageSessionSpy()
        let newPublisherSpy = VonagePublisherSpy()
        let publisherRepository = MockPublisherRepository()
        publisherRepository.publisherToReturn = newPublisherSpy

        let sut = makeSUT(
            session: session,
            publisher: publisherSpy,
            publisherRepository: publisherRepository
        )
        sut.setup()

        try await sut.connect()

        await delay()

        let advancedSettings = PublisherAdvancedSettings(videoResolution: .high)

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(newPublisherSpy.videoTransformers.count == 2)
        #expect(newPublisherSpy.videoTransformers.first?.key == "blur")
    }

    @Test
    func applyPublisherAdvancedSettings_restoresAudioTransformers() async throws {
        let publisherSpy = VonagePublisherSpy()
        let transformer1 = MockTransformer(key: "NoiseSuppression", transformer: NSObject())
        let transformer2 = MockTransformer(key: "AudioEffect", transformer: NSObject())
        publisherSpy.setAudioTransformers([transformer1, transformer2])

        let session = VonageSessionSpy()
        let newPublisherSpy = VonagePublisherSpy()
        let publisherRepository = MockPublisherRepository()
        publisherRepository.publisherToReturn = newPublisherSpy

        let sut = makeSUT(
            session: session,
            publisher: publisherSpy,
            publisherRepository: publisherRepository
        )
        sut.setup()

        try await sut.connect()

        await delay()

        let advancedSettings = PublisherAdvancedSettings(videoResolution: .high)

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(newPublisherSpy.audioTransformers.count == 2)
        #expect(newPublisherSpy.audioTransformers.first?.key == "NoiseSuppression")
    }

    // MARK: - Test Helpers

    private func makeSUT(
        credentials: RoomCredentials = makeMockCredentials(),
        session: VonageSession = VonageSessionSpy(),
        publisher: VonagePublisher = VonagePublisherSpy(),
        publisherRepository: PublisherRepository = MockPublisherRepository(),
        statsCollector: StatsCollector = MockStatsCollector()
    ) -> VonageCall {
        VonageCall(
            roomName: credentials.roomName,
            makeSession: { _ in session },
            publisher: publisher,
            publisherRepository: publisherRepository,
            statsCollector: statsCollector
        )
    }

    private func makeOpaqueStream() -> OTStream {
        OTStream()
    }

    private func makeBaseSession() -> VonageSession {
        VonageSession(
            session: OTSession(
                applicationId: "applicationId",
                sessionId: "sessionId",
                delegate: nil
            )!,
            credentials: makeMockCredentials()
        )
    }
}

private enum ForceMuteTestError: Swift.Error, Equatable {
    case requestFailed
}


@Suite("CallTerminationTests", .serialized)
@MainActor
struct CallTerminationTests {
    private func makeCall(_ session: VonageSession = CallTerminationTestsSession()) -> VonageCall {
        VonageCall(
            roomName: makeMockCredentials().roomName, makeSession: { _ in session },
            publisher: VonagePublisherSpy(), publisherRepository: MockPublisherRepository(),
            statsCollector: MockStatsCollector())
    }

    @Test func reviewConnectFailureTerminatesCall() async throws {
        let call = makeCall(ThrowingVonageSession())
        var state: CallState = .idle
        let observation = call.callState.sink { state = $0 }
        call.setup()
        await #expect(throws: ThrowingVonageSession.Error.self) { try await call.connect() }
        #expect(state == .disconnected, "connect failure leaves call stuck connecting")
        observation.cancel()
    }

    @Test func reviewCanCancelConnectingCall() async throws {
        let session = CallTerminationTestsSession()
        let call = makeCall(session)
        call.setup()
        try await call.connect()
        do { try await call.disconnect() } catch { Issue.record("Cannot cancel connecting call: \(error)") }
        #expect(session.disconnectCount == 1)
    }

    @Test func reviewTerminalSessionFailureCleansUpCall() async throws {
        let session = CallTerminationTestsSession()
        let call = makeCall(session)
        var state: CallState = .idle
        let observation = call.callState.sink { state = $0 }
        call.setup()
        try await call.connect()
        session.onSessionFailure?(NSError(domain: "review", code: 1))
        try await Task.sleep(for: .milliseconds(200))
        #expect(state == .disconnected, "unrecoverable session error never cleans up call")
        observation.cancel()
    }

    @Test func cancellingWhileCredentialsResolveCannotStartTheLateSession() async throws {
        let session = CallTerminationTestsSession()
        var pending: CheckedContinuation<VonageSession, Error>?
        let call = VonageCall(
            roomName: makeMockCredentials().roomName,
            makeSession: { _ in try await withCheckedThrowingContinuation { pending = $0 } },
            publisher: VonagePublisherSpy(), publisherRepository: MockPublisherRepository(),
            statsCollector: MockStatsCollector())
        var states: [CallState] = []
        let observation = call.callState.sink { states.append($0) }
        defer { observation.cancel() }
        call.setup()
        let connecting = Task { @MainActor in try await call.connect() }
        for _ in 0..<100 where pending == nil { await Task.yield() }
        let continuation = try #require(pending)
        do { try await call.disconnect() } catch { Issue.record("Cannot cancel credential resolution: \(error)") }
        continuation.resume(returning: session)
        _ = try? await connecting.value
        #expect(session.connectCount == 0)
        #expect(session.cleanupCount == 1)
        #expect(states.last == .disconnected)
        #expect(states.contains(.disconnecting))
    }

    @Test func lateConnectionCallbackDoesNotResurrectAnEndedCall() async throws {
        let session = CallTerminationTestsSession()
        let call = makeCall(session)
        var state: CallState = .idle
        let observation = call.callState.sink { state = $0 }
        defer { observation.cancel() }
        call.setup()
        try await call.connect()
        let lateCallback = session.onSessionDidConnect
        do { try await call.disconnect() } catch { Issue.record("Cannot end connecting call: \(error)") }
        lateCallback?()
        #expect(state == .disconnected)
        #expect(session.publishCount == 0)
    }

    @Test func repeatedDisconnectRunsCleanupOnlyOnce() async throws {
        let session = CallTerminationTestsSession()
        let call = makeCall(session)
        call.setup()
        try await call.connect()
        session.onSessionDidConnect?()
        let first = Task { @MainActor in try await call.disconnect() }
        let second = Task { @MainActor in try await call.disconnect() }
        do {
            try await first.value
            try await second.value
            try await call.disconnect()
        } catch { Issue.record("Repeated disconnect must be safe: \(error)") }
        #expect(session.disconnectCount == 1)
        #expect(session.cleanupCount == 1)
    }

    @Test func unexpectedSessionDisconnectCleansUpResources() async throws {
        let session = CallTerminationTestsSession()
        let call = makeCall(session)
        var state: CallState = .idle
        let observation = call.callState.sink { state = $0 }
        defer { observation.cancel() }
        call.setup()
        try await call.connect()
        session.onSessionDidConnect?()
        session.onSessionDidDisconnect?()
        try await Task.sleep(for: .milliseconds(200))
        #expect(state == .disconnected)
        #expect(session.cleanupCount == 1)
    }
    @Test func synchronousConnectionFailureIsRethrownAfterCleanup() async throws {
        let call = makeCall(ThrowingVonageSession())
        var capturedError: Swift.Error?
        call.setup()
        do { try await call.connect() } catch { capturedError = error }
        #expect(capturedError is ThrowingVonageSession.Error)
    }

    @Test(arguments: [true, false])
    func terminalCallbackImmediatelyRejectsLateConnect(isFailure: Bool) async throws {
        let session = CallTerminationTestsSession()
        let call = makeCall(session)
        call.setup()
        try await call.connect()
        let lateConnect = session.onSessionDidConnect
        if isFailure {
            session.onSessionFailure?(NSError(domain: "terminal", code: 1))
        } else {
            session.onSessionDidDisconnect?()
        }
        lateConnect?()
        #expect(session.publishCount == 0)
        try await Task.sleep(for: .milliseconds(100))
    }

    @Test(arguments: [true, false])
    func credentialProviderReceivesCancellation(cancelCaller: Bool) async throws {
        var started = false
        var cancelled = false
        let call = VonageCall(
            roomName: makeMockCredentials().roomName,
            makeSession: { _ in
                started = true
                do { try await Task.sleep(for: .seconds(10)) } catch {
                    cancelled = Task.isCancelled
                    throw error
                }
                return CallTerminationTestsSession()
            }, publisher: VonagePublisherSpy(), publisherRepository: MockPublisherRepository(),
            statsCollector: MockStatsCollector())
        call.setup()
        let connecting = Task { @MainActor in try await call.connect() }
        for _ in 0..<100 where !started { await Task.yield() }
        #expect(started)
        if cancelCaller { connecting.cancel() } else { try await call.disconnect() }
        try await Task.sleep(for: .milliseconds(100))
        #expect(cancelled)
        connecting.cancel()
        _ = try? await connecting.value
    }

}

private final class CallTerminationTestsSession: VonageSession {
    var disconnectCount = 0
    var connectCount = 0
    var cleanupCount = 0
    var publishCount = 0
    init() {
        super.init(
            session: OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!,
            credentials: makeMockCredentials())
    }
    override func connect() throws { connectCount += 1 }
    override func disconnect() throws { disconnectCount += 1 }
    override func publish(publisher: VonagePublisher) throws { publishCount += 1 }
    override func cleanUp() {
        cleanupCount += 1
        super.cleanUp()
    }
    override func unpublish(publisher: VonagePublisher) throws {}
}


private final class DisconnectFailureSession: ThrowingVonageSession {
    override func connect() throws {}
    override func publish(publisher: VonagePublisher) throws {}
}
