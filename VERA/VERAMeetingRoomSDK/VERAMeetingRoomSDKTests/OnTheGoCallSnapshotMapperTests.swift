//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import Testing
import VERADomain
import VERAMeetingRoom

@testable import VERAMeetingRoomSDK

@Suite("OnTheGoCallSnapshotMapper tests")
struct OnTheGoCallSnapshotMapperTests {

    @Test("Loading state maps to the disconnected snapshot")
    func loadingMapsToDisconnected() {
        let snapshot = OnTheGoCallSnapshotMapper.snapshot(from: .loading)

        #expect(snapshot == .disconnected)
    }

    @Test("A connected room maps media, remote count, speaker, and the share")
    func connectedRoomMapsCallFields() {
        let room = makeRoom(
            callState: .connected,
            participants: [
                participant(id: "local", name: "You", isRemote: false, isScreenshare: false),
                participant(id: "alice", name: "Alice", isRemote: true, isScreenshare: false),
                participant(id: "share", name: "Alice's screen", isRemote: true, isScreenshare: true),
            ],
            activeSpeakerId: "alice",
            isMicEnabled: true,
            isCameraEnabled: false
        )

        let snapshot = OnTheGoCallSnapshotMapper.snapshot(from: .content(room))

        #expect(snapshot.isConnected)
        #expect(snapshot.isMicEnabled)
        #expect(!snapshot.isCameraEnabled)
        #expect(snapshot.participantCount == 1)
        #expect(snapshot.activeSpeakerName == "Alice")
        #expect(snapshot.screenShareParticipant?.id == "share")
        #expect(snapshot.screenShareParticipant?.name == "Alice's screen")
    }

    @Test("A screenshare is not reported as the active speaker")
    func screenshareIsNotTheActiveSpeaker() {
        let room = makeRoom(
            callState: .connected,
            participants: [
                participant(id: "share", name: "Slides", isRemote: true, isScreenshare: true)
            ],
            activeSpeakerId: "share"
        )

        let snapshot = OnTheGoCallSnapshotMapper.snapshot(from: .content(room))

        #expect(snapshot.activeSpeakerName == nil)
        #expect(snapshot.participantCount == 0)
    }

    @Test("A call that is not connected maps to the disconnected snapshot")
    func disconnectingMapsToDisconnected() {
        let room = makeRoom(callState: .disconnecting, participants: [])

        #expect(OnTheGoCallSnapshotMapper.snapshot(from: .content(room)) == .disconnected)
    }

    private func participant(
        id: String,
        name: String,
        isRemote: Bool,
        isScreenshare: Bool
    ) -> UIParticipant {
        UIParticipant(
            participant: Participant(
                id: id,
                name: name,
                isMicEnabled: true,
                isCameraEnabled: true,
                videoDimensions: .zero,
                isRemote: isRemote,
                creationTime: .distantPast,
                isScreenshare: isScreenshare,
                view: AnyView(EmptyView())
            )
        )
    }

    private func makeRoom(
        callState: CallState,
        participants: [UIParticipant],
        activeSpeakerId: String? = nil,
        isMicEnabled: Bool = true,
        isCameraEnabled: Bool = true
    ) -> MeetingRoomState {
        MeetingRoomState(
            roomName: "room",
            roomURL: nil,
            isMicEnabled: isMicEnabled,
            isCameraEnabled: isCameraEnabled,
            participants: participants,
            layout: .activeSpeaker,
            activeSpeakerId: activeSpeakerId,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            showParticipantList: true,
            callState: callState,
            archivingState: .idle,
            noiseSuppressionState: .idle
        )
    }
}
