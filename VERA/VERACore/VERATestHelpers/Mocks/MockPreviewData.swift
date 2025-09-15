//
//  Created by Vonage on 12/8/25.
//

import Foundation
import SwiftUI
import VERACore

struct PreviewData {
    // MARK: - Individual Participants
    static let arthurDent = Participant(
        id: "1",
        name: "Arthur Dent",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.red) }
    )

    static let fordPrefect = Participant(
        id: "2",
        name: "Ford Prefect",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.green) }
    )

    static let zaphodBeeblebrox = Participant(
        id: "3",
        name: "Zaphod Beeblebrox",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.blue) }
    )

    static let trillian = Participant(
        id: "4",
        name: "Trillian",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.yellow) }
    )

    static let marvin = Participant(
        id: "5",
        name: "Marvin",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.purple) }
    )

    static let slartibartfast = Participant(
        id: "6",
        name: "Slartibartfast",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.orange) }
    )

    static let eddie = Participant(
        id: "7",
        name: "Eddie",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.cyan) }
    )

    static let hummaKavula = Participant(
        id: "8",
        name: "Humma Kavula",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.mint) }
    )

    static let fenchurch = Participant(
        id: "9",
        name: "Fenchurch",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.pink) }
    )

    // MARK: - Special State Participants
    static let cameraOffParticipant = Participant(
        id: "cam_off",
        name: "Camera Off",
        isMicEnabled: true,
        isCameraEnabled: false,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.red) }
    )

    static let micOffParticipant = Participant(
        id: "mic_off",
        name: "Mic Off",
        isMicEnabled: false,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        isPinned: false,
        viewBuilder: { AnyView(Color.blue) }
    )

    // MARK: - Array Collections
    static let participants: [Participant] = [
        arthurDent,
        fordPrefect,
        zaphodBeeblebrox,
        trillian,
        marvin,
        slartibartfast,
        eddie,
        hummaKavula,
        fenchurch,
    ]

    static let singleParticipant = arthurDent
    static let twoParticipants = [arthurDent, fordPrefect]
    static let manyParticipants = participants

    static let mixedStates: [Participant] = [
        cameraOffParticipant,
        micOffParticipant,
    ]
}
