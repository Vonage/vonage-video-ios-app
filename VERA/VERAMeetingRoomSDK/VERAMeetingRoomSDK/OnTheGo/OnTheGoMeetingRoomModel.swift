//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import VERAMeetingRoom
import VERAOnTheGo

/// Maps meeting-room state into the snapshot ``OnTheGoViewModel`` consumes.
enum OnTheGoCallSnapshotMapper {

    static func snapshot(from state: MeetingRoomViewState) -> OnTheGoCallSnapshot {
        guard case .content(let room) = state, room.callState == .connected else {
            return .disconnected
        }

        let speaker = room.participants.first { participant in
            participant.id == room.activeSpeakerId && !participant.isScreenshare
        }
        let share = room.participants.first(where: \.isScreenshare)

        return OnTheGoCallSnapshot(
            isConnected: true,
            isMicEnabled: room.isMicEnabled,
            isCameraEnabled: room.isCameraEnabled,
            participantCount: room.participants.count { $0.isRemote && !$0.isScreenshare },
            activeSpeakerName: speaker?.name,
            screenShareParticipant: share.map(shareParticipant)
        )
    }

    private static func shareParticipant(_ participant: UIParticipant) -> OnTheGoCallSnapshot.Participant {
        .init(
            id: participant.id,
            name: participant.name,
            isScreenshare: true,
            view: participant.view,
            onAppear: participant.onAppear,
            onDisappear: participant.onDisappear
        )
    }
}

/// Owns the On-the-Go view model for one meeting room and keeps it fed with
/// call snapshots. One instance is shared by the call UI, the more menu, and
/// the settings row so they read the same preferences.
@MainActor
final class OnTheGoMeetingRoomModel {
    let factory: OnTheGoFactory
    let viewModel: OnTheGoViewModel

    init(meetingRoom: MeetingRoomViewModel) {
        let factory = OnTheGoFactory.makeDefault()
        self.factory = factory
        viewModel = factory.makeViewModel(
            actions: OnTheGoCallActions(
                toggleMic: { meetingRoom.onToggleMic() },
                toggleCamera: { meetingRoom.onToggleCamera() },
                endCall: { meetingRoom.endCall() }
            )
        )
    }

    func push(_ state: MeetingRoomViewState) {
        viewModel.update(snapshot: OnTheGoCallSnapshotMapper.snapshot(from: state))
    }
}
