//
//  Created by Vonage on 19/9/25.
//

import Foundation
import VERACore
import VERADomain

/// Manages call participant state and active-speaker tracking.
///
/// `CallStateManager` stores subscribers and participants, recalculates the active speaker
/// on membership changes, and exposes the current `ParticipantsState` snapshot.
///
/// ## Responsibilities
/// - Add/remove subscribers and keep participants in sync
/// - Persist participant updates
/// - Compute active speaker via ``ActiveSpeakerTracker``
/// - Provide the current participants state to the UI/domain
///
/// - Note: This is an `actor` to serialize mutations and state access across concurrency.
final actor CallStateManager {
    private let subscribersRepository = SubscribersRepository()
    private let participantsRepository = ParticipantsRepository()
    private let activeSpeakerTracker: ActiveSpeakerTracker

    /// Creates a state manager with the given active-speaker tracker.
    ///
    /// - Parameter activeSpeakerTracker: Strategy used to update and compute the active speaker.
    init(activeSpeakerTracker: ActiveSpeakerTracker) {
        self.activeSpeakerTracker = activeSpeakerTracker
    }

    /// Adds a subscriber, persists its participant, recomputes active speaker, and returns state.
    ///
    /// - Parameter subscriber: The newly joined Vonage subscriber.
    /// - Returns: The updated ``ParticipantsState`` snapshot after the mutation.
    func addSubscriber(_ subscriber: VonageSubscriber) async -> ParticipantsState {
        await subscribersRepository.addSubscriber(subscriber)
        await participantsRepository.saveParticipant(subscriber.participant)
        await recalculateActiveSpeaker()
        return await getCurrentState()
    }

    /// Removes a subscriber and its participant, recomputes active speaker, and returns state.
    ///
    /// - Parameter id: The subscriber/participant identifier to remove.
    /// - Returns: A tuple containing:
    ///   - `subscriber`: The removed subscriber instance (if any)
    ///   - `state`: The updated ``ParticipantsState`` snapshot
    func removeSubscriber(id: String) async -> (subscriber: VonageSubscriber?, state: ParticipantsState) {
        let subscriber = await subscribersRepository.getSubscriber(id: id)
        await subscribersRepository.removeSubscriber(id: id)
        await participantsRepository.removeParticipant(id: id)
        await recalculateActiveSpeaker()
        let state = await getCurrentState()
        return (subscriber, state)
    }

    /// Updates and persists a participant, returning the latest state.
    ///
    /// - Parameter participant: The participant with updated properties (e.g., mic/camera).
    /// - Returns: The updated ``ParticipantsState`` snapshot.
    func updateParticipant(_ participant: Participant) async -> ParticipantsState {
        await participantsRepository.saveParticipant(participant)
        return await getCurrentState()
    }

    /// Updates active-speaker levels/flags for a participant.
    ///
    /// Forwards the update to the ``ActiveSpeakerTracker`` which may change
    /// the `activeSpeaker` based on audio level and microphone state.
    ///
    /// - Parameter speakerInfo: The participant’s audio level and mic status.
    func updateActiveSpeaker(_ speakerInfo: SpeakerInfo) {
        activeSpeakerTracker.updatedParticipant(speakerInfo)
    }

    /// Returns the current participants state, including the active participant ID.
    ///
    /// - Returns: ``ParticipantsState`` with:
    ///   - `localParticipant`: Always `nil` here (managed elsewhere)
    ///   - `participants`: All known remote participants
    ///   - `activeParticipantId`: From the active-speaker tracker
    func getCurrentState() async -> ParticipantsState {
        .init(
            localParticipant: nil,
            participants: await participantsRepository.all,
            activeParticipantId: activeSpeakerTracker.activeSpeaker.participantId
        )
    }

    /// Recalculates the active speaker based on current participants.
    ///
    /// Builds `SpeakerInfo` from repository entries and delegates to the tracker.
    private func recalculateActiveSpeaker() async {
        let participants = await participantsRepository.all
        activeSpeakerTracker.calculateActiveSpeaker(
            from: participants.map {
                SpeakerInfo(id: $0.id, audioLevel: 0, isMicEnabled: $0.isMicEnabled)
            }
        )
    }

    /// Cleans up all participants and subscribers, calling their teardown where applicable.
    ///
    /// Invokes `cleanUp()` on each subscriber and resets both repositories.
    func cleanUpParticipants() async {
        await subscribersRepository.all.forEach { $0.cleanUp() }
        await subscribersRepository.reset()
        await participantsRepository.reset()
    }

    /// Sets on-hold state for all subscribers.
    ///
    /// - Parameter isOnHold: `true` to hold; `false` to resume.
    func setOnHold(_ isOnHold: Bool) async {
        await subscribersRepository.all.forEach { $0.setOnHold(isOnHold) }
    }

    func enableCaptions() async {
        await subscribersRepository.all.forEach { $0.enableCaptions() }
    }

    func disableCaptions() async {
        await subscribersRepository.all.forEach { $0.disableCaptions() }
    }
}
