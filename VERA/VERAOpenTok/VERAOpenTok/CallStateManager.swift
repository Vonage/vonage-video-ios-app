//
//  Created by Vonage on 19/9/25.
//

import Foundation
import VERACore

final actor CallStateManager {
    private let subscribersRepository = SubscribersRepository()
    private let participantsRepository = ParticipantsRepository()
    private let activeSpeakerTracker = ActiveSpeakerTracker()

    func addSubscriber(_ subscriber: OpenTokSubscriber) async -> ParticipantsState {
        await subscribersRepository.addSubscriber(subscriber)
        await participantsRepository.saveParticipant(subscriber.participant)
        await recalculateActiveSpeaker()
        return await getCurrentState()
    }

    func removeSubscriber(id: String) async -> (subscriber: OpenTokSubscriber?, state: ParticipantsState) {
        let subscriber = await subscribersRepository.getSubscriber(id: id)
        await subscribersRepository.removeSubscriber(id: id)
        await participantsRepository.removeParticipant(id: id)
        await recalculateActiveSpeaker()
        let state = await getCurrentState()
        return (subscriber, state)
    }

    func updateParticipant(_ participant: Participant) async -> ParticipantsState {
        await participantsRepository.saveParticipant(participant)
        return await getCurrentState()
    }

    func updateActiveSpeaker(_ speakerInfo: SpeakerInfo) async -> ParticipantsState {
        activeSpeakerTracker.updatedParticipant(speakerInfo)
        return await getCurrentState()
    }

    private func getCurrentState() async -> ParticipantsState {
        .init(localParticipant: nil,
              participants: await participantsRepository.all,
              activeParticipantId: activeSpeakerTracker.activeSpeaker.participantId)
    }

    private func recalculateActiveSpeaker() async {
        let participants = await participantsRepository.all
        activeSpeakerTracker.calculateActiveSpeaker(
            from: participants.map {
                SpeakerInfo(id: $0.id, audioLevel: 0, isMicEnabled: $0.isMicEnabled)
            })
    }
}
