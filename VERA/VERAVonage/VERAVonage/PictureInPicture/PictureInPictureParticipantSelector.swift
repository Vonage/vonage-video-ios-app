//
//  Created by Vonage on 21/6/26.
//

import Foundation
import VERADomain

/// Decides which participant Picture-in-Picture should follow and exposes the participant lookups
/// (name, camera state) needed to keep the PiP placeholder in sync.
///
/// This is pure selection policy: it holds only the "sticky" default-target memory and never touches
/// renderers, the AVKit controller, or the active call. The orchestrator feeds it `ParticipantsState`
/// and acts on the identifiers it returns.
@MainActor
final class PictureInPictureParticipantSelector {
    /// Default (out-of-PiP) target we stay pinned to so the tile does not thrash between remotes.
    private var stickyPipTargetId: String?

    func reset() {
        stickyPipTargetId = nil
    }

    /// Prefers the first joined remote; falls back to any remote with camera when the first has video off.
    /// When there are no remote participants, falls back to the local participant so PiP works solo.
    func pipTargetId(for state: ParticipantsState) -> String? {
        let remoteParticipants = sortedRemoteParticipants(in: state)
        guard !remoteParticipants.isEmpty else {
            stickyPipTargetId = nil
            return state.localParticipant?.id
        }

        if stickyPipTargetId == nil || !remoteParticipants.contains(where: { $0.id == stickyPipTargetId }) {
            stickyPipTargetId = remoteParticipants.first?.id
        }

        guard let stickyPipTargetId,
            let stickyParticipant = remoteParticipants.first(where: { $0.id == stickyPipTargetId })
        else {
            return remoteParticipants.first?.id
        }

        if stickyParticipant.isCameraEnabled {
            return stickyParticipant.id
        }

        return remoteParticipants.first(where: { $0.isCameraEnabled })?.id ?? stickyParticipant.id
    }

    /// PiP target while Picture-in-Picture is active: follow the detected active speaker.
    ///
    /// Falls back to the current target when there is no active speaker (avoids thrashing back to
    /// the sticky default when everyone goes quiet), and finally to the standard sticky selection.
    func activeSpeakerPipTargetId(for state: ParticipantsState, currentPipTargetId: String?) -> String? {
        if let activeId = state.activeParticipantId,
            state.participants.contains(where: { $0.id == activeId && !$0.isScreenshare })
        {
            return activeId
        }

        if let currentPipTargetId,
            currentPipTargetId == state.localParticipant?.id
                || state.participants.contains(where: { $0.id == currentPipTargetId })
        {
            return currentPipTargetId
        }

        return pipTargetId(for: state)
    }

    private func sortedRemoteParticipants(in state: ParticipantsState) -> [Participant] {
        state.participants
            .filter { !$0.isScreenshare }
            .sorted { $0.creationTime < $1.creationTime }
    }

    // MARK: - Participant lookups

    static func participantName(for participantId: String?, in state: ParticipantsState) -> String {
        guard let participantId else { return "" }

        if state.localParticipant?.id == participantId {
            return state.localParticipant?.name ?? ""
        }

        return state.participants.first(where: { $0.id == participantId })?.name ?? ""
    }

    static func isCameraEnabled(participantId: String?, in state: ParticipantsState) -> Bool {
        guard let participantId else { return false }

        if state.localParticipant?.id == participantId {
            return state.localParticipant?.isCameraEnabled == true
        }

        return state.participants.first(where: { $0.id == participantId })?.isCameraEnabled == true
    }

    // MARK: - Change coalescing

    /// A compact, `Equatable` snapshot of everything that can affect the PiP target or placeholder.
    /// Used to coalesce participant-state emissions and ignore audio-level-only updates.
    struct Signature: Equatable {
        let localId: String?
        let localCameraEnabled: Bool
        let activeParticipantId: String?
        let remotes: [Remote]

        struct Remote: Equatable {
            let id: String
            let cameraEnabled: Bool
            let isScreenshare: Bool
        }
    }

    static func signature(for state: ParticipantsState) -> Signature {
        Signature(
            localId: state.localParticipant?.id,
            localCameraEnabled: state.localParticipant?.isCameraEnabled ?? false,
            activeParticipantId: state.activeParticipantId,
            remotes: state.participants.map {
                Signature.Remote(
                    id: $0.id,
                    cameraEnabled: $0.isCameraEnabled,
                    isScreenshare: $0.isScreenshare
                )
            }
        )
    }
}
