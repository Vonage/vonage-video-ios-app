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

        var event: SessionEvent?
        let observation = sut.eventsPublisher.sink { value in
            if case .error = value { event = value }
        }
        defer { observation.cancel() }
        try await sut.connect()

        switch event {
        case .error(let error):
            #expect(error is ThrowingVonageSession.Error)
        default:
            Issue.record("Expected error event, got: \(String(describing: event))")
        }
    }

    @Test
    func disconnectPublishesErrorWhenSessionThrows() async throws {
        let session = ThrowingVonageSession()
        let sut = makeSUT(session: session)
        sut.setup()

        var event: SessionEvent?
        let observation = sut.eventsPublisher.sink { value in
            if case .error = value { event = value }
        }
        defer { observation.cancel() }
        try? await sut.disconnect()

        switch event {
        case .error: break
        // Should be an error
        default:
            Issue.record("Expected error event, got: \(String(describing: event))")
        }
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

        var states: [CallState] = []
        let observation = sut.callState.sink { states.append($0) }
        defer { observation.cancel() }
        await #expect(throws: MakeSessionError.self) {
            try await sut.connect()
        }

        #expect(states == [.idle, .connecting, .disconnected])
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

    @Test("Moderator mute publishes local state and its event", .timeLimit(.minutes(1)))
    func publisherMuteForcedUpdatesLocalStateAndPublishesEvent() async throws {
        let publisherSpy = VonagePublisherSpy()
        let sut = makeSUT(publisher: publisherSpy)
        sut.setup()
        try await sut.connect()

        var state: SessionState?
        var receivedMuteForced = false
        let muteForcedPublished = ValueWorkerTestGate()
        let stateObservation = sut.statePublisher.sink { state = $0 }
        let eventObservation = sut.eventsPublisher.sink { event in
            if case .muteForced = event {
                receivedMuteForced = true
                Task { await muteForcedPublished.open() }
            }
        }
        defer {
            stateObservation.cancel()
            eventObservation.cancel()
        }
        publisherSpy.muteForced(publisherSpy.exposedOTPublisher)
        await muteForcedPublished.wait()

        #expect(publisherSpy.publishAudio == false)
        #expect(state?.isPublishingAudio == false)
        #expect(receivedMuteForced)
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

    @Test("A plugin failure is reported while every plugin still starts, ends, and releases its call")
    func pluginFailuresDoNotInterruptOtherPluginLifecycles() async throws {
        let session = VonageSessionSpy()
        let failing = LifecycleFailurePlugin(shouldFail: true)
        let healthy = LifecycleFailurePlugin(shouldFail: false)
        let sut = makeSUT(session: session)
        let startFailureReported = ValueWorkerTestGate()
        var errors: [LifecycleFailurePlugin.Failure] = []
        var state: CallState = .idle
        let eventObservation = sut.eventsPublisher.sink { event in
            guard case .error(let error) = event,
                let failure = error as? LifecycleFailurePlugin.Failure
            else { return }
            errors.append(failure)
            if failure == .start { Task { await startFailureReported.open() } }
        }
        let stateObservation = sut.callState.sink { state = $0 }
        sut.assignPlugins([failing, healthy])
        sut.setup()
        try await sut.connect()
        await startFailureReported.wait()
        #expect(state == .connected)
        #expect(failing.call === sut)
        #expect(failing.channel === session)

        try await sut.disconnect()

        #expect(errors == [.start, .end])
        #expect(failing.actions == ["start", "end"])
        #expect(healthy.actions == ["start", "end"])
        #expect(failing.call == nil && healthy.call == nil)
        #expect(failing.channel == nil && healthy.channel == nil)
        #expect(sut.plugins.isEmpty)
        #expect(state == .disconnected)
        #expect(session.disconnectCalled)
        withExtendedLifetime((eventObservation, stateObservation)) {}
    }

    // MARK: - Archiving

    @Test
    func archiveStartedWithTranscriptionNameUpdatesOnlyTranscriptionState() async throws {
        let session = VonageSessionSpy()
        let sut = try await makeConnectedSUT(session: session)

        session.onArchiveStarted?("transcription-1", "transcription")

        #expect(await currentValue(of: sut.transcriptionState) == .archiving("transcription-1"))
        #expect(await currentValue(of: sut.archivingState) == .idle)
    }

    @Test
    func archiveStartedWithoutNameIsTreatedAsRecording() async throws {
        let session = VonageSessionSpy()
        let sut = try await makeConnectedSUT(session: session)

        session.onArchiveStarted?("recording-1", nil)

        #expect(await currentValue(of: sut.archivingState) == .archiving("recording-1"))
        #expect(await currentValue(of: sut.transcriptionState) == .idle)
    }

    @Test
    func stoppingRecordingKeepsTranscriptionRunning() async throws {
        let session = VonageSessionSpy()
        let sut = try await makeConnectedSUT(session: session)
        session.onArchiveStarted?("recording-1", "recording")
        session.onArchiveStarted?("transcription-1", "transcription")

        session.onArchiveStopped?("recording-1")

        #expect(await currentValue(of: sut.archivingState) == .idle)
        #expect(await currentValue(of: sut.transcriptionState) == .archiving("transcription-1"))
    }

    @Test
    func stoppingTranscriptionKeepsRecordingRunning() async throws {
        let session = VonageSessionSpy()
        let sut = try await makeConnectedSUT(session: session)
        session.onArchiveStarted?("recording-1", "recording")
        session.onArchiveStarted?("transcription-1", "transcription")

        session.onArchiveStopped?("transcription-1")

        #expect(await currentValue(of: sut.transcriptionState) == .idle)
        #expect(await currentValue(of: sut.archivingState) == .archiving("recording-1"))
    }

    @Test
    func stoppingAnUntrackedArchiveKeepsRunningArchives() async throws {
        let session = VonageSessionSpy()
        let sut = try await makeConnectedSUT(session: session)
        session.onArchiveStarted?("recording-1", "recording")
        session.onArchiveStarted?("transcription-1", "transcription")

        session.onArchiveStopped?("unknown-archive")

        #expect(await currentValue(of: sut.archivingState) == .archiving("recording-1"))
        #expect(await currentValue(of: sut.transcriptionState) == .archiving("transcription-1"))
    }

    @Test
    func archiveEventsForwardTheArchiveKindToSignalHandlers() async throws {
        let session = VonageSessionSpy()
        let plugin = ArchivingSignalHandlerSpy()
        let sut = makeSUT(session: session)
        sut.assignPlugins([plugin])
        sut.setup()
        try await sut.connect()

        session.onArchiveStarted?("transcription-1", "transcription")
        session.onArchiveStopped?("transcription-1")

        let payloads = try plugin.signals.map { try #require($0.data) }
        #expect(payloads.count == 2)
        #expect(payloads.allSatisfy { $0.contains(#""kind":"transcription""#) })
        #expect(payloads.first?.contains(#""archivingID":"transcription-1""#) == true)
    }

    // MARK: - Test Helpers

    private func makeConnectedSUT(session: VonageSessionSpy) async throws -> VonageCall {
        let sut = makeSUT(session: session)
        sut.setup()
        try await sut.connect()
        return sut
    }

    private func currentValue(
        of publisher: AnyPublisher<ArchivingState, Never>
    ) async -> ArchivingState? {
        await publisher.values.first { _ in true }
    }

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

private final class ArchivingSignalHandlerSpy: VonagePlugin, VonageSignalHandler {
    private(set) var signals: [VonageSignal] = []

    var pluginIdentifier: String { "ArchivingSignalHandlerSpy" }

    func callDidStart(_ userInfo: [String: Any]) async throws {}

    func callDidEnd() async throws {}

    func handleSignal(_ signal: VonageSignal) {
        guard signal.type == "archiving" else { return }
        signals.append(signal)
    }
}

@Suite("SystemMediaStateTests", .serialized)
@MainActor
struct SystemMediaStateTests {
    private func makeCall(_ session: VonageSession = SystemMediaStateTestsSession()) -> VonageCall {
        VonageCall(
            roomName: makeMockCredentials().roomName, makeSession: { _ in session },
            publisher: VonagePublisherSpy(), publisherRepository: MockPublisherRepository(),
            statsCollector: MockStatsCollector())
    }

    @Test func reviewCallKitUnmutePreservesDisabledCamera() async throws {
        let call = makeCall()
        call.publisher.publishVideo = false
        call.setup()
        call.muteLocalAudio(true)
        try await Task.sleep(for: .milliseconds(100))
        call.muteLocalAudio(false)
        try await Task.sleep(for: .milliseconds(100))
        #expect(!call.publisher.publishVideo, "system unmute switches a disabled camera on")
    }

    @Test func reviewMuteLocalMediaPublishesState() async throws {
        let call = makeCall()
        var latest: SessionState = .initial
        let observation = call.statePublisher.sink { latest = $0 }
        call.setup()
        call.muteLocalMedia(true)
        try await Task.sleep(for: .milliseconds(200))
        #expect(!call.publisher.publishAudio && !call.publisher.publishVideo)
        #expect(
            !latest.isPublishingAudio && !latest.isPublishingVideo,
            "CallKit media changes do not update the UI state publisher")
        observation.cancel()
    }

    @Test(arguments: [true, false])
    func systemMutePreservesVideoAndPublishesState(cameraEnabled: Bool) async throws {
        let call = makeCall()
        call.publisher.publishVideo = cameraEnabled
        var state: SessionState = .initial
        let observation = call.statePublisher.sink { state = $0 }
        defer { observation.cancel() }
        call.setup()
        call.muteLocalAudio(true)
        try await Task.sleep(for: .milliseconds(100))
        #expect(!call.publisher.publishAudio)
        #expect(call.publisher.publishVideo == cameraEnabled)
        #expect(!state.isPublishingAudio && state.isPublishingVideo == cameraEnabled)
        call.muteLocalAudio(false)
        try await Task.sleep(for: .milliseconds(100))
        #expect(call.publisher.publishAudio)
        #expect(call.publisher.publishVideo == cameraEnabled)
        #expect(state.isPublishingAudio && state.isPublishingVideo == cameraEnabled)
    }

    @Test(arguments: [true, false])
    func holdAndResumePublishActualMediaState(audioInitiallyEnabled: Bool) async throws {
        let call = makeCall()
        call.publisher.publishAudio = audioInitiallyEnabled
        call.publisher.publishVideo = false
        var state: SessionState = .initial
        let observation = call.statePublisher.sink { state = $0 }
        defer { observation.cancel() }
        call.setup()
        call.setOnHold(true)
        try await Task.sleep(for: .milliseconds(100))
        #expect(!state.isPublishingAudio && !state.isPublishingVideo)
        call.muteLocalAudio(audioInitiallyEnabled)
        try await Task.sleep(for: .milliseconds(100))
        #expect(!call.publisher.publishAudio && !call.publisher.publishVideo)
        call.setOnHold(false)
        try await Task.sleep(for: .milliseconds(100))
        #expect(state.isPublishingAudio == !audioInitiallyEnabled)
        #expect(!state.isPublishingVideo)
    }
}

private final class SystemMediaStateTestsSession: VonageSession {
    var disconnectCount = 0
    init() {
        super.init(
            session: OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!,
            credentials: makeMockCredentials())
    }
    override func connect() throws {}
    override func disconnect() throws { disconnectCount += 1 }
    override func publish(publisher: VonagePublisher) throws {}
    override func unpublish(publisher: VonagePublisher) throws {}
}

@Suite("CallObserverLifetimeTests", .serialized)
@MainActor
struct CallObserverLifetimeTests {
    private func makeCall(_ session: VonageSession = CallObserverLifetimeTestsSession()) -> VonageCall {
        VonageCall(
            roomName: makeMockCredentials().roomName, makeSession: { _ in session },
            publisher: VonagePublisherSpy(), publisherRepository: MockPublisherRepository(),
            statsCollector: MockStatsCollector())
    }

    @Test func reviewSetupCallReleasesWhenOwnerDropsIt() async throws {
        var call: VonageCall? = makeCall()
        weak var observed = call
        call?.setup()
        try await Task.sleep(for: .milliseconds(100))
        call = nil
        try await Task.sleep(for: .milliseconds(300))
        #expect(observed == nil, "setup observer keeps call alive after its owner releases it")
    }

    @Test func reviewCallWithoutObserversReleases() async throws {
        var call: VonageCall? = makeCall()
        weak var observed = call
        call = nil
        try await Task.sleep(for: .milliseconds(100))
        #expect(observed == nil)
    }

    @Test func reviewNormalDisconnectReleasesCall() async throws {
        let session = CallObserverLifetimeTestsSession()
        var call: VonageCall? = makeCall(session)
        weak var observed = call
        call?.setup()
        try await call?.connect()
        session.onSessionDidConnect?()
        try await Task.sleep(for: .milliseconds(100))
        try await call?.disconnect()
        call = nil
        try await Task.sleep(for: .milliseconds(300))
        #expect(observed == nil)
    }
}

private final class CallObserverLifetimeTestsSession: VonageSession {
    var disconnectCount = 0
    init() {
        super.init(
            session: OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!,
            credentials: makeMockCredentials())
    }
    override func connect() throws {}
    override func disconnect() throws { disconnectCount += 1 }
    override func publish(publisher: VonagePublisher) throws {}
    override func unpublish(publisher: VonagePublisher) throws {}
}


@MainActor
@Suite("Plugin initialization and disconnect ordering", .timeLimit(.minutes(1)))
struct CallPluginLifecycleOrderingTests {
    @Test("Disconnect joins cancellation-ignoring initialization and ignores late connect callbacks")
    func disconnectFinishesInitializationBeforeEndingPlugin() async throws {
        let session = CallObserverLifetimeTestsSession()
        let plugin = SuspendedStartPlugin()
        let publisher = VonagePublisherSpy()
        let collector = MockStatsCollector()
        let call = VonageCall(
            roomName: makeMockCredentials().roomName, makeSession: { _ in session },
            publisher: publisher, publisherRepository: MockPublisherRepository(),
            statsCollector: collector)
        var states: [CallState] = []
        let observation = call.callState.sink { states.append($0) }
        call.assignPlugins([plugin])
        call.setup()
        try await call.connect()
        session.onSessionDidConnect?()
        await plugin.startEntered.wait()
        var didEnd = false
        let end = Task {
            try await call.disconnect()
            didEnd = true
        }
        await plugin.startCancelled.wait()
        #expect(!didEnd)
        #expect(plugin.actions == ["start:begin"])
        session.onSessionDidConnect?()
        #expect(states.last == .disconnecting)
        call.enableNetworkStats()
        call.enableSubscriberExtraStats()
        #expect(collector.requestRtcStatsFromPublisherCallCount == 0)
        #expect(publisher.exposedOTPublisher.networkStatsDelegate == nil)
        await plugin.releaseStart.open()
        try await end.value
        #expect(plugin.actions == ["start:begin", "start:finished", "end"])
        #expect(states.last == .disconnected)
        withExtendedLifetime(observation) {}
    }
}

@MainActor
private final class SuspendedStartPlugin: VonagePlugin {
    let startEntered = ValueWorkerTestGate()
    let startCancelled = ValueWorkerTestGate()
    let releaseStart = ValueWorkerTestGate()
    var actions: [String] = []
    var pluginIdentifier: String { "SuspendedStartPlugin" }

    func callDidStart(_ userInfo: [String: Any]) async throws {
        actions.append("start:begin")
        await startEntered.open()
        await withTaskCancellationHandler {
            await releaseStart.wait()
        } onCancel: {
            Task { await self.startCancelled.open() }
        }
        actions.append("start:finished")
    }

    func callDidEnd() async throws { actions.append("end") }
}

@MainActor
private final class LifecycleFailurePlugin: VonagePlugin, VonagePluginCallHolder, VonageSignalEmitter {
    enum Failure: Error, Equatable { case start, end }
    var call: CallFacade?
    var channel: VonageSignalChannel?
    var actions: [String] = []
    private let shouldFail: Bool
    var pluginIdentifier: String { shouldFail ? "failing" : "healthy" }

    init(shouldFail: Bool) { self.shouldFail = shouldFail }

    func callDidStart(_ userInfo: [String: Any]) async throws {
        actions.append("start")
        if shouldFail { throw Failure.start }
    }

    func callDidEnd() async throws {
        actions.append("end")
        if shouldFail { throw Failure.end }
    }
}
