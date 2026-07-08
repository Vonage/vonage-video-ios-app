//
//  Created by Vonage on 8/7/26.
//

import Foundation
import SwiftUI
import Testing
import VERADomain

@testable import VERAVonage

@Suite("PictureInPictureParticipantSelector tests")
@MainActor
struct PictureInPictureParticipantSelectorTests {

    // MARK: - pipTargetId

    @Test("Solo call has no PiP target (local is never shown in PiP)")
    func soloYieldsNoTarget() {
        let sut = PictureInPictureParticipantSelector()
        let state = makeState(local: makeParticipant(id: "local", isRemote: false), remotes: [])

        #expect(sut.pipTargetId(for: state) == nil)
    }

    @Test("No participants at all yields no target")
    func emptyStateYieldsNil() {
        let sut = PictureInPictureParticipantSelector()

        #expect(sut.pipTargetId(for: .empty) == nil)
    }

    @Test("First joined remote becomes the sticky target")
    func firstJoinedRemoteWins() {
        let sut = PictureInPictureParticipantSelector()
        let state = makeState(remotes: [
            makeParticipant(id: "late", joinedAt: 100),
            makeParticipant(id: "early", joinedAt: 1),
        ])

        #expect(sut.pipTargetId(for: state) == "early")
    }

    @Test("Sticky target survives newer joiners")
    func stickySurvivesNewJoiners() {
        let sut = PictureInPictureParticipantSelector()
        let first = makeParticipant(id: "first", joinedAt: 1)
        #expect(sut.pipTargetId(for: makeState(remotes: [first])) == "first")

        let withNewcomer = makeState(remotes: [first, makeParticipant(id: "newcomer", joinedAt: 2)])
        #expect(sut.pipTargetId(for: withNewcomer) == "first")
    }

    @Test("Sticky target leaving moves to the next first-joined remote")
    func stickyLeavingFallsToNext() {
        let sut = PictureInPictureParticipantSelector()
        let first = makeParticipant(id: "first", joinedAt: 1)
        let second = makeParticipant(id: "second", joinedAt: 2)
        #expect(sut.pipTargetId(for: makeState(remotes: [first, second])) == "first")

        #expect(sut.pipTargetId(for: makeState(remotes: [second])) == "second")
    }

    @Test("Camera-off sticky yields to a camera-enabled remote but is not forgotten")
    func cameraOffStickyYieldsTemporarily() {
        let sut = PictureInPictureParticipantSelector()
        let sticky = makeParticipant(id: "sticky", joinedAt: 1)
        let other = makeParticipant(id: "other", joinedAt: 2)
        #expect(sut.pipTargetId(for: makeState(remotes: [sticky, other])) == "sticky")

        let stickyCameraOff = makeParticipant(id: "sticky", cameraEnabled: false, joinedAt: 1)
        #expect(sut.pipTargetId(for: makeState(remotes: [stickyCameraOff, other])) == "other")

        // Sticky's camera returns: selection snaps back.
        #expect(sut.pipTargetId(for: makeState(remotes: [sticky, other])) == "sticky")
    }

    @Test("All remotes camera-off keeps the sticky target")
    func allCamerasOffKeepsSticky() {
        let sut = PictureInPictureParticipantSelector()
        let state = makeState(remotes: [
            makeParticipant(id: "a", cameraEnabled: false, joinedAt: 1),
            makeParticipant(id: "b", cameraEnabled: false, joinedAt: 2),
        ])

        #expect(sut.pipTargetId(for: state) == "a")
    }

    @Test("Screenshares are never targeted; a real remote is chosen instead")
    func screensharesExcluded() {
        let sut = PictureInPictureParticipantSelector()
        let state = makeState(
            remotes: [
                makeParticipant(id: "share", isScreenshare: true, joinedAt: 1),
                makeParticipant(id: "camera", joinedAt: 2),
            ]
        )

        #expect(sut.pipTargetId(for: state) == "camera")
    }

    @Test("reset forgets the sticky target")
    func resetForgetsSticky() {
        let sut = PictureInPictureParticipantSelector()
        let first = makeParticipant(id: "first", joinedAt: 1)
        let second = makeParticipant(id: "second", cameraEnabled: false, joinedAt: 2)
        _ = sut.pipTargetId(for: makeState(remotes: [second]))

        sut.reset()

        #expect(sut.pipTargetId(for: makeState(remotes: [first, second])) == "first")
    }

    // MARK: - activeSpeakerPipTargetId

    @Test("In PiP the active speaker is preferred")
    func activeSpeakerPreferred() {
        let sut = PictureInPictureParticipantSelector()
        let state = makeState(
            remotes: [makeParticipant(id: "a", joinedAt: 1), makeParticipant(id: "b", joinedAt: 2)],
            activeSpeakerId: "b"
        )

        #expect(sut.activeSpeakerPipTargetId(for: state, currentPipTargetId: "a") == "b")
    }

    @Test("A screenshare active speaker is ignored")
    func screenshareActiveSpeakerIgnored() {
        let sut = PictureInPictureParticipantSelector()
        let state = makeState(
            remotes: [
                makeParticipant(id: "a", joinedAt: 1),
                makeParticipant(id: "share", isScreenshare: true, joinedAt: 2),
            ],
            activeSpeakerId: "share"
        )

        #expect(sut.activeSpeakerPipTargetId(for: state, currentPipTargetId: "a") == "a")
    }

    @Test("No active speaker keeps the current target")
    func quietRoomKeepsCurrentTarget() {
        let sut = PictureInPictureParticipantSelector()
        let state = makeState(
            remotes: [makeParticipant(id: "a", joinedAt: 1), makeParticipant(id: "b", joinedAt: 2)]
        )

        #expect(sut.activeSpeakerPipTargetId(for: state, currentPipTargetId: "b") == "b")
    }

    @Test("Current target leaving falls back to sticky selection")
    func departedTargetFallsBackToSticky() {
        let sut = PictureInPictureParticipantSelector()
        let state = makeState(remotes: [makeParticipant(id: "a", joinedAt: 1)])

        #expect(sut.activeSpeakerPipTargetId(for: state, currentPipTargetId: "gone") == "a")
    }

    // MARK: - ParticipantSignature

    @Test("Audio-level-only changes produce equal signatures")
    func audioLevelChangesCoalesced() {
        let quiet = makeState(remotes: [makeParticipant(id: "a", audioLevel: 0.0, joinedAt: 1)])
        let loud = makeState(remotes: [makeParticipant(id: "a", audioLevel: 0.9, joinedAt: 1)])

        #expect(
            PictureInPictureParticipantSelector.signature(for: quiet)
                == PictureInPictureParticipantSelector.signature(for: loud))
    }

    @Test("Camera, participant-set, and active-speaker changes produce distinct signatures")
    func meaningfulChangesDetected() {
        let base = makeState(remotes: [makeParticipant(id: "a", joinedAt: 1)])
        let cameraOff = makeState(remotes: [makeParticipant(id: "a", cameraEnabled: false, joinedAt: 1)])
        let extraRemote = makeState(remotes: [
            makeParticipant(id: "a", joinedAt: 1), makeParticipant(id: "b", joinedAt: 2),
        ])
        let speaking = makeState(remotes: [makeParticipant(id: "a", joinedAt: 1)], activeSpeakerId: "a")

        let signature = PictureInPictureParticipantSelector.signature(for: base)
        #expect(signature != PictureInPictureParticipantSelector.signature(for: cameraOff))
        #expect(signature != PictureInPictureParticipantSelector.signature(for: extraRemote))
        #expect(signature != PictureInPictureParticipantSelector.signature(for: speaking))
    }
}

// MARK: - Helpers

private func makeParticipant(
    id: String,
    cameraEnabled: Bool = true,
    isRemote: Bool = true,
    isScreenshare: Bool = false,
    audioLevel: Float = 0.0,
    joinedAt: TimeInterval = 0
) -> Participant {
    Participant(
        id: id,
        name: id,
        isMicEnabled: true,
        isCameraEnabled: cameraEnabled,
        videoDimensions: .zero,
        isRemote: isRemote,
        creationTime: Date(timeIntervalSince1970: joinedAt),
        isScreenshare: isScreenshare,
        audioLevel: audioLevel,
        view: AnyView(EmptyView()))
}

private func makeState(
    local: Participant? = nil,
    remotes: [Participant],
    activeSpeakerId: String? = nil
) -> ParticipantsState {
    ParticipantsState(
        localParticipant: local,
        participants: remotes,
        activeParticipantId: activeSpeakerId)
}
