//
//  Created by Vonage on 7/6/26.
//

import Combine
import Testing
import VERADomain

@testable import VERAE2E

@Suite("E2E call facade tests")
struct E2ECallFacadeTests {

    @Test("Call facade publishes deterministic state changes")
    func callFacadePublishesDeterministicStateChanges() async throws {
        let sut = E2ECallFacade(
            publisherSettings: .init(
                publishAudio: true,
                publishVideo: true))

        var states = [SessionState]()
        let stateCancellable = sut.statePublisher.sink { state in
            states.append(state)
        }

        var callStates = [CallState]()
        let callStateCancellable = sut.callState.sink { state in
            callStates.append(state)
        }

        var events = [SessionEvent]()
        let eventsCancellable = sut.eventsPublisher.sink { event in
            events.append(event)
        }

        var retainedCancellables = Set<AnyCancellable>()
        sut.networkStatsPublisher.sink { _ in }.store(in: &retainedCancellables)
        sut.participantsPublisher.sink { _ in }.store(in: &retainedCancellables)
        sut.archivingState.sink { _ in }.store(in: &retainedCancellables)
        sut.captionsPublisher.sink { _ in }.store(in: &retainedCancellables)

        sut.connect()
        sut.toggleLocalVideo()
        sut.toggleLocalAudio()
        sut.muteLocalMedia(true)
        sut.setOnHold(true)
        sut.enableNetworkStats()
        sut.disableNetworkStats()
        try await sut.applyPublisherAdvancedSettings(.init(maxAudioBitrate: 24_000))
        try await sut.disconnect()

        #expect(states.first?.isPublishingAudio == true)
        #expect(states.first?.isPublishingVideo == true)
        #expect(states.contains { $0.isPublishingAudio && !$0.isPublishingVideo })
        #expect(states.contains { !$0.isPublishingAudio && !$0.isPublishingVideo })
        #expect(sut.isMuted)
        #expect(sut.isOnHold)
        #expect(callStates.contains(where: isConnected))
        #expect(callStates.contains(where: isDisconnecting))
        #expect(callStates.last.map(isDisconnected) == true)
        #expect(events.contains(where: isConnected))
        #expect(events.last.map(isDisconnected) == true)

        stateCancellable.cancel()
        callStateCancellable.cancel()
        eventsCancellable.cancel()
    }

    @Test("Call facade disables captions")
    func callFacadeDisablesCaptions() async {
        let sut = E2ECallFacade()
        var captionEmissions = [[CaptionItem]]()
        let cancellable = sut.captionsPublisher.sink { captions in
            captionEmissions.append(captions)
        }

        await sut.enableCaptions()
        await sut.disableCaptions()

        #expect(!sut.areCaptionsEnabled)
        #expect(captionEmissions.last?.isEmpty == true)
        cancellable.cancel()
    }
}

private func isConnected(_ state: CallState) -> Bool {
    if case .connected = state { return true }
    return false
}

private func isDisconnecting(_ state: CallState) -> Bool {
    if case .disconnecting = state { return true }
    return false
}

private func isDisconnected(_ state: CallState) -> Bool {
    if case .disconnected = state { return true }
    return false
}

private func isConnected(_ event: SessionEvent) -> Bool {
    if case .connected = event { return true }
    return false
}

private func isDisconnected(_ event: SessionEvent) -> Bool {
    if case .disconnected = event { return true }
    return false
}
