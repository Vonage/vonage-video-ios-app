//
//  Created by Vonage on 7/8/25.
//

import Foundation
import SwiftUI

struct PreviewData {
    static let participants: [Participant] = [
        .init(
            id: "1",
            name: "Arthur Dent",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.red)),
        .init(
            id: "2",
            name: "Ford Prefect",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.green)),
        .init(
            id: "3",
            name: "Zaphod Beeblebrox",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.blue)),
        .init(
            id: "4",
            name: "Trillian",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.yellow)),
        .init(
            id: "5",
            name: "Marvin",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.purple)),
        .init(
            id: "6",
            name: "Slartibartfast",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.orange)),
        .init(
            id: "7",
            name: "Eddie",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.cyan)),
        .init(
            id: "8",
            name: "Humma Kavula",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.mint)),
        .init(
            id: "9",
            name: "Fenchurch",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.pink)),
    ]

    static let singleParticipant = Array(participants.prefix(1))
    static let twoParticipants = Array(participants.prefix(2))
    static let manyParticipants = participants

    static let mixedStates: [Participant] = [
        .init(
            id: "cam_off",
            name: "Camera Off",
            isMicEnabled: true,
            isCameraEnabled: false,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(EmptyView())),
        .init(
            id: "mic_off",
            name: "Mic Off",
            isMicEnabled: false,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            view: AnyView(Color.red)),
    ]
}
