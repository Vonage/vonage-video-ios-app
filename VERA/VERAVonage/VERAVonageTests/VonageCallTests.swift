//
//  Created by Vonage on 28/7/25.
//

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
        let session = VonageSessionSpy()
        let sut = makeSUT(
            credentials: makeMockCredentials(
                token: aToken
            ), session: session)
        sut.setup()

        #expect(session.connectCalled == false)
        #expect(session.recordedTokens.isEmpty)
        sut.connect()
        #expect(session.connectCalled == true)
        #expect(session.recordedTokens == [aToken])
    }

    @Test
    func connectPublishesErrorWhenSessionThrows() async throws {
        let session = ThrowingVonageSession()
        let sut = makeSUT(session: session)
        sut.setup()

        sut.connect()

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
        let session = ThrowingVonageSession()
        let sut = makeSUT(session: session)
        sut.setup()

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
        sut.participantStreamResolver = { id in
            #expect(id == "participant-id")
            return stream
        }

        try await sut.forceMuteParticipant(id: "participant-id")

        #expect(session.forceMutedStreams.count == 1)
        #expect(session.forceMutedStreams.first === stream)
    }

    @Test
    func forceMuteParticipantPropagatesSessionError() async {
        let stream = makeOpaqueStream()
        let session = VonageSessionSpy()
        session.forceMuteError = ForceMuteTestError.requestFailed
        let sut = makeSUT(session: session)
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
        sut.connect()

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

        sut.connect()

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

        sut.connect()

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

        sut.connect()
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

        sut.connect()

        let advancedSettings = PublisherAdvancedSettings(videoResolution: .high)

        try await sut.applyPublisherAdvancedSettings(advancedSettings)

        #expect(newPublisherSpy.exposedOTPublisher.networkStatsDelegate == nil)
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

        sut.connect()

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

        sut.connect()

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

        sut.connect()

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
            credentials: credentials,
            session: session,
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
            )!
        )
    }
}

private enum ForceMuteTestError: Swift.Error, Equatable {
    case requestFailed
}
