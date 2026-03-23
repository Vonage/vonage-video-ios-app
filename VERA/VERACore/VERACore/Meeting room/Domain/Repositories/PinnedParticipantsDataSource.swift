//
//  Created by Vonage on 17/3/26.
//

import Combine

/// Interface for managing pinned participant state.
///
/// Implementations track which participants are pinned and expose a reactive
/// publisher so the ViewModel can merge pin state into ``UIParticipant`` values.
public protocol PinnedParticipantsDataSource {
    /// A publisher emitting the current set of pinned participant IDs.
    var pinnedParticipantIds: AnyPublisher<Set<String>, Never> { get }

    /// Toggles the pin state for the given participant.
    ///
    /// If the participant is currently pinned, it will be unpinned, and vice versa.
    /// - Parameter participantId: The ID of the participant to toggle.
    func togglePin(participantId: String) async

    /// Removes all pinned participants.
    func reset() async
}
