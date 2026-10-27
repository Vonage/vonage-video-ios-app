import Combine
import Testing
import VERADomain
import VERAE2E

@Suite("E2E call hold and media choices")
@MainActor
struct E2ECallFacadeMediaTests {
    @Test(arguments: [true, false], [true, false])
    func microphoneChoiceWhileHeldIsDeferredUntilResume(cameraEnabled: Bool, muted: Bool) {
        let call = makeSUT(audioEnabled: muted, cameraEnabled: cameraEnabled)
        var states: [SessionState] = []
        let observation = call.statePublisher.sink { states.append($0) }
        defer { observation.cancel() }

        call.setOnHold(true)
        #expect(call.isOnHold)
        #expect(states.last?.isPublishingAudio == false)
        #expect(states.last?.isPublishingVideo == false)
        call.muteLocalAudio(muted)
        #expect(states.last?.isPublishingAudio == false)
        #expect(states.last?.isPublishingVideo == false)
        call.setOnHold(false)

        #expect(!call.isOnHold)
        #expect(states.last?.isPublishingAudio == !muted)
        #expect(states.last?.isPublishingVideo == cameraEnabled)
        #expect(states.dropFirst().dropLast().allSatisfy { !$0.isPublishingAudio && !$0.isPublishingVideo })
    }

    @Test func repeatedHoldDoesNotOverwriteSavedMediaChoices() {
        let call = makeSUT(audioEnabled: true, cameraEnabled: true)
        var latest: SessionState?
        let observation = call.statePublisher.sink { latest = $0 }
        defer { observation.cancel() }

        call.setOnHold(true)
        call.muteLocalAudio(true)
        call.setOnHold(true)
        call.setOnHold(false)
        call.setOnHold(false)

        #expect(latest?.isPublishingAudio == false)
        #expect(latest?.isPublishingVideo == true)
        #expect(!call.isMuted)
    }

    @Test func mediaControlsUpdateSavedChoicesWithoutPublishingWhileHeld() {
        let call = makeSUT(audioEnabled: true, cameraEnabled: false)
        var states: [SessionState] = []
        let observation = call.statePublisher.sink { states.append($0) }
        defer { observation.cancel() }

        call.setOnHold(true)
        call.muteLocalMedia(false)
        call.toggleLocalVideo()
        call.toggleLocalAudio()
        #expect(states.dropFirst().allSatisfy { !$0.isPublishingAudio && !$0.isPublishingVideo })
        call.setOnHold(false)
        #expect(states.last?.isPublishingAudio == false)
        #expect(states.last?.isPublishingVideo == false)
        #expect(call.isMuted)
    }

    @Test func speakingWhileMutedSimulationResumesAfterHold() async throws {
        let call = makeSUT(audioEnabled: true, cameraEnabled: false)
        call.toggleLocalAudio()

        call.setOnHold(true)
        #expect(call._publisherAudioLevelPublisher.value == 0.0)
        call.setOnHold(false)
        try await Task.sleep(for: .milliseconds(500))

        #expect(call._publisherAudioLevelPublisher.value == 0.5)
        call.toggleLocalAudio()
    }

    @Test(arguments: [false, true])
    func systemUnmuteStopsSpeakingWhileMutedSimulation(unmutesAllMedia: Bool) async throws {
        let call = makeSUT(audioEnabled: true, cameraEnabled: false)
        call.toggleLocalAudio()
        try await Task.sleep(for: .milliseconds(500))
        #expect(call._publisherAudioLevelPublisher.value == 0.5)

        if unmutesAllMedia {
            call.muteLocalMedia(false)
        } else {
            call.muteLocalAudio(false)
        }
        try await Task.sleep(for: .milliseconds(500))

        #expect(call._publisherAudioLevelPublisher.value == 0.0, "simulation keeps running after a system unmute")
    }

    private func makeSUT(audioEnabled: Bool, cameraEnabled: Bool) -> E2ECallFacade {
        E2ECallFacade(publisherSettings: .init(publishAudio: audioEnabled, publishVideo: cameraEnabled))
    }
}
