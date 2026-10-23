import Combine
import Foundation
import OpenTok
import Testing
import VERATestHelpers

@testable import VERAVonage

@MainActor
@Suite("Publisher callback lifetime")
struct VonagePublisherCallbackLifetimeTests {
    @Test("Cleanup ignores callbacks until setup reactivates the cached wrapper")
    func setupReactivatesCallbacksAfterCleanup() {
        let publisher = VonagePublisherSpy()
        var levels: [Float] = []
        let observation = publisher.audioLevelPublisher.sink { levels.append($0) }
        publisher.publisher(publisher.exposedOTPublisher, audioLevelUpdated: 1)
        #expect(levels.count == 2)
        publisher.cleanUp()
        publisher.publisher(publisher.exposedOTPublisher, audioLevelUpdated: 0.1)
        #expect(levels.count == 2)
        publisher.setup()
        publisher.publisher(publisher.exposedOTPublisher, audioLevelUpdated: 0.1)
        #expect(levels.count == 3)
        #expect(levels.last != 1)
        withExtendedLifetime(observation) {}
    }

    @Test("Stream lifecycle callbacks preserve order and ignore callbacks after cleanup")
    func streamLifecycleCallbacksRespectCleanup() {
        let publisher = VonagePublisherSpy()
        // These delegate callbacks consume no stream fields; an opaque SDK object is sufficient.
        let stream = OTStream()
        var events: [String] = []
        publisher.onStreamCreated = { events.append("created") }
        publisher.onStreamDestroyed = { events.append("destroyed") }
        publisher.publisher(publisher.exposedOTPublisher, streamCreated: stream)
        publisher.publisher(publisher.exposedOTPublisher, streamDestroyed: stream)
        #expect(events == ["created", "destroyed"])

        publisher.cleanUp()
        publisher.publisher(publisher.exposedOTPublisher, streamCreated: stream)
        publisher.publisher(publisher.exposedOTPublisher, streamDestroyed: stream)
        #expect(events == ["created", "destroyed"])

        publisher.setup()
        publisher.onStreamCreated = { events.append("recreated") }
        publisher.publisher(publisher.exposedOTPublisher, streamCreated: stream)
        #expect(events == ["created", "destroyed", "recreated"])
    }

    @Test("Repeated setup does not duplicate participant observations or emissions")
    func repeatedSetupDoesNotDuplicateObservers() {
        let publisher = VonagePublisherSpy()
        var participantEmissions = 0
        let observation = publisher.$participant.sink { _ in participantEmissions += 1 }
        publisher.setup()
        let emissionsAfterFirstSetup = participantEmissions
        publisher.setup()
        #expect(participantEmissions == emissionsAfterFirstSetup)
        withExtendedLifetime(observation) {}
    }


    @Test("A reused publisher receives an error emitted inside native publish", .timeLimit(.minutes(1)))
    func reusedPublisherReceivesCallbackBeforePostPublishSetup() async throws {
        let publisher = VonagePublisherSpy()
        publisher.cleanUp()
        let session = ImmediatePublisherFailureSession()
        let receivedFailure = ValueWorkerTestGate()
        var receivedError: Error?
        publisher.onError = { error in
            receivedError = error
            Task { await receivedFailure.open() }
        }
        let call = VonageCall(
            roomName: "room", makeSession: { _ in session }, publisher: publisher,
            publisherRepository: MockPublisherRepository(), statsCollector: MockStatsCollector())
        call.setup()
        try await call.connect()
        await receivedFailure.wait()
        #expect((receivedError as? OTError)?.code == 1500)
    }


    @Test("Background audio values are smoothed before one coalesced UI delivery", .timeLimit(.minutes(1)))
    func backgroundAudioValuesPreserveSmoothing() async {
        let publisher = VonagePublisherSpy()
        // Supply scalar callback values independently of live SDK audio capture.
        publisher.exposedOTPublisher.audioLevelDelegate = nil
        publisher.cleanUp()
        publisher.prepareCallbackDelivery()
        let samples: [Float] = [1, 0.5, 0.25, 0.1]
        let reference = MovingAvgAudioLevelTracker()
        let expected = samples.map { round(reference.track($0).logMovingAvg * 100) / 100 }.last!
        var received: [Float] = []
        let produced = DispatchSemaphore(value: 0)
        var observation: AnyCancellable?
        await withCheckedContinuation { continuation in
            observation = publisher.audioLevelPublisher.dropFirst().sink { value in
                received.append(value)
                continuation.resume()
            }
            DispatchQueue.global().async {
                for sample in samples { publisher.receiveAudioLevel(sample) }
                produced.signal()
            }
            // Hold UI delivery until this bounded background callback burst is fully queued.
            #expect(produced.wait(timeout: .now() + 2) == .success)
        }
        observation?.cancel()
        #expect(received == [expected])
        #expect(publisher.audioLevel == expected)
    }

}


@MainActor
private final class ImmediatePublisherFailureSession: VonageSessionSpy {
    override func publish(publisher: VonagePublisher) throws {
        publisher.publisher(
            publisher.otPublisher,
            didFailWithError: OTError(domain: OT_PUBLISHER_ERROR_DOMAIN, code: 1500, userInfo: nil))
    }
}
