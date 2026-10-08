import Combine
import OpenTok
import Testing
import VERADomain
import VERAFeedback
import VERATestHelpers
import VERAVonage

@testable import VERAMeetingRoomSDK

@Suite("Feedback session debug info tests")
struct FeedbackSessionDebugInfoCurrentCallTests {

    @Test("fromCurrentCall returns session metadata for an active Vonage call")
    func fromCurrentCallReturnsSessionMetadataForVonageCall() async throws {
        let session = TestVonageSession()
        let call = VonageCall(
            roomName: "heart-of-gold",
            makeSession: { _ in session },
            publisher: TestVonagePublisher(),
            publisherRepository: TestPublisherRepository(),
            statsCollector: TestStatsCollector())
        try await call.connect()

        let repository = makeMockSessionRepository()
        repository.currentCall = call

        let debugInfo = FeedbackSessionDebugInfo.fromCurrentCall(in: repository)

        #expect(debugInfo.sessionId == "sessionId")
        #expect(debugInfo.connectionId == nil)
        #expect(debugInfo.connectionCreationTime == nil)
    }

    @Test("fromCurrentCall returns empty when current call is not a VonageCall")
    func fromCurrentCallReturnsEmptyForNonVonageCall() {
        let repository = makeMockSessionRepository()
        repository.currentCall = MockCall()

        let debugInfo = FeedbackSessionDebugInfo.fromCurrentCall(in: repository)

        #expect(debugInfo == .empty)
    }

    @Test("fromCurrentCall returns empty when there is no active call")
    func fromCurrentCallReturnsEmptyWhenNoCall() {
        let repository = makeMockSessionRepository()

        let debugInfo = FeedbackSessionDebugInfo.fromCurrentCall(in: repository)

        #expect(debugInfo == .empty)
    }
}

private final class TestVonageSession: VonageSession {
    init() {
        super.init(
            session: OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!,
            credentials: RoomCredentials(
                sessionId: "sessionId",
                token: "token",
                applicationId: "applicationId",
                roomName: "heart-of-gold",
                sessionKey: "sessionKey"))
    }

    override func connect() throws {}
}

private final class TestVonagePublisher: VonagePublisher {
    init() {
        super.init(
            publisher: OTPublisher(delegate: nil)!,
            transformerFactory: MockTransformerFactory())
    }
}

private final class TestPublisherRepository: PublisherRepository {
    func getPublisher() throws -> any VERAPublisher {
        TestVonagePublisher()
    }

    func resetPublisher() {}

    func recreatePublisher(_ settings: PublisherSettings) throws {}
}

private final class TestStatsCollector: NSObject, StatsCollector {
    var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        Empty().eraseToAnyPublisher()
    }

    func reset() {}

    func requestRtcStats(from subscriber: OTSubscriberKit) {}

    func requestRtcStats(from publisher: OTPublisherKit) {}

    func removeSubscriber(connectionId: String) {}

    func publisher(
        _ publisher: OTPublisherKit,
        videoNetworkStatsUpdated stats: [OTPublisherKitVideoNetworkStats]
    ) {}

    func publisher(
        _ publisher: OTPublisherKit,
        audioNetworkStatsUpdated stats: [OTPublisherKitAudioNetworkStats]
    ) {}

    func subscriber(
        _ subscriber: OTSubscriberKit,
        videoNetworkStatsUpdated stats: [OTSubscriberKitVideoNetworkStats]
    ) {}

    func subscriber(
        _ subscriber: OTSubscriberKit,
        audioNetworkStatsUpdated stats: [OTSubscriberKitAudioNetworkStats]
    ) {}

    func publisher(_ publisher: OTPublisherKit, rtcStatsReport stats: [OTPublisherRtcStats]) {}

    func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport jsonArrayString: String) {}

    func publisher(
        _ publisher: OTPublisherKit,
        mediaLinkStatsUpdated mediaLinkStats: [OTPublisherKitMediaLinkStats]
    ) {}

    func subscriber(
        _ subscriber: OTSubscriberKit,
        mediaLinkStatsUpdated mediaLinkStats: OTSubscriberKitMediaLinkStats
    ) {}
}
