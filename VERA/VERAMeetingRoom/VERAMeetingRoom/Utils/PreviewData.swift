//
//  Created by Vonage on 7/8/25.
//

import Foundation
import SwiftUI
import VERADomain

public struct PreviewData {
    // MARK: - Individual Participants
    public static let arthurDent = Participant(
        id: "1",
        name: "Arthur Dent",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.red)
    )

    public static let fordPrefect = Participant(
        id: "2",
        name: "Ford Prefect",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.green)
    )

    public static let zaphodBeeblebrox = Participant(
        id: "3",
        name: "Zaphod Beeblebrox",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.blue)
    )

    public static let trillian = Participant(
        id: "4",
        name: "Trillian",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.yellow)
    )

    public static let marvin = Participant(
        id: "5",
        name: "Marvin",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.purple)
    )

    public static let slartibartfast = Participant(
        id: "6",
        name: "Slartibartfast",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.orange)
    )

    public static let eddie = Participant(
        id: "7",
        name: "Eddie",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.cyan)
    )

    public static let hummaKavula = Participant(
        id: "8",
        name: "Humma Kavula",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.mint)
    )

    public static let fenchurch = Participant(
        id: "9",
        name: "Fenchurch",
        isMicEnabled: true,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.pink)
    )

    // MARK: - Special State Participants
    public static let cameraOffParticipant = Participant(
        id: "cam_off",
        name: "Camera Off",
        isMicEnabled: true,
        isCameraEnabled: false,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.red)
    )

    public static let micOffParticipant = Participant(
        id: "mic_off",
        name: "Mic Off",
        isMicEnabled: false,
        isCameraEnabled: true,
        videoDimensions: .zero,
        creationTime: Date(),
        isScreenshare: false,
        view: AnyView(Color.blue)
    )

    // MARK: - Array Collections
    public static let participants: [Participant] = [
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

    public static let singleParticipant = arthurDent
    public static let twoParticipants = [arthurDent, fordPrefect]
    public static let manyParticipants = participants

    public static let mixedStates: [Participant] = [
        cameraOffParticipant,
        micOffParticipant,
    ]

    // MARK: - UIParticipant Collections
    public static let uiSingleParticipant = UIParticipant(participant: arthurDent, isPinned: false)
    public static let uiTwoParticipants = [
        UIParticipant(participant: arthurDent, isPinned: false),
        UIParticipant(participant: fordPrefect, isPinned: false),
    ]
    public static let uiManyParticipants = participants.map { UIParticipant(participant: $0, isPinned: false) }
}
