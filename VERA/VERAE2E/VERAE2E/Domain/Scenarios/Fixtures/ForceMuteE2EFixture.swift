//
//  Created by Vonage on 29/6/26.
//

import Foundation
import SwiftUI
import VERADomain

struct ForceMuteE2EFixture: E2EScenarioFixture {
    static let localPublisherID = "e2e-local-publisher"
    static let localPublisherName = "Moderator"
    static let participantID = "e2e-remote-participant"
    static let participantName = "Remote Participant"

    let participantsState = ParticipantsState(
        localParticipant: Participant(
            id: localPublisherID,
            name: localPublisherName,
            isMicEnabled: true,
            isCameraEnabled: false,
            videoDimensions: .init(width: 640, height: 480),
            isRemote: false,
            creationTime: Date(timeIntervalSince1970: 1_754_638_878),
            isScreenshare: false,
            view: AnyView(EmptyView())
        ),
        participants: [
            Participant(
                id: participantID,
                name: participantName,
                isMicEnabled: true,
                isCameraEnabled: false,
                videoDimensions: .init(width: 640, height: 480),
                isRemote: true,
                creationTime: Date(timeIntervalSince1970: 1_754_638_879),
                isScreenshare: false,
                view: AnyView(EmptyView())
            )
        ],
        activeParticipantId: nil)
}
