//
//  Created by Vonage on 23/7/25.
//

import AVKit
import SwiftUI

struct ParticipantVideoCard: View {
    let participant: Participant

    private let containerAspectRatio: Double = 16.0 / 9.0

    var body: some View {
        Group {
            if participant.isCameraEnabled {
                ZStack {
                    Rectangle()
                        .fill(.vGray4.opacity(0.8))
                        .aspectRatio(containerAspectRatio, contentMode: .fit)
                        .overlay(
                            ZStack {
                                participant.view
                                    .scaleEffect(x: participant.isRemote ? -1 : 1, y: 1)
                                    .aspectRatio(participant.aspectRatio, contentMode: .fit)
                                    .clipped()

                                ParticipantVideoCardOverlays(
                                    isMicEnabled: participant.isMicEnabled,
                                    name: participant.name
                                )
                            }
                        )
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(.vGray4.opacity(0.8))
                        .aspectRatio(containerAspectRatio, contentMode: .fit)
                        .overlay(
                            AvatarInitials(state: .init(userName: participant.name))
                                .padding(24)
                        )

                    ParticipantVideoCardOverlays(
                        isMicEnabled: participant.isMicEnabled,
                        name: participant.name
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
    }
}

struct ParticipantVideoCardOverlays: View {

    let isMicEnabled: Bool
    let name: String

    var body: some View {
        VStack {
            HStack {
                Spacer()
                MicIndicator(isMicEnabled: isMicEnabled)
            }
            Spacer()
            HStack {
                NameLabel(name: name)
                Spacer()
            }
        }
        .padding(8)
    }
}

struct NameLabel: View {
    var name: String
    var body: some View {
        Text(name)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

struct MicIndicator: View {
    var isMicEnabled: Bool
    var body: some View {
        Image(systemName: isMicEnabled ? "mic.fill" : "mic.slash.fill")
            .foregroundColor(.white)
            .padding(6)
            .background(Color.black.opacity(0.6))
            .clipShape(Circle())
            .frame(width: 28, height: 28)
    }
}

#Preview {
    ParticipantVideoCard(
        participant: Participant(
            id: "",
            name: "name",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            audioLevel: 0,
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView()))
    )
}

#Preview {
    ParticipantVideoCard(
        participant: Participant(
            id: "",
            name: "name",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            audioLevel: 0,
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView()))
    )
}

#Preview {
    ParticipantVideoCard(
        participant: Participant(
            id: "",
            name: "name",
            isMicEnabled: false,
            isCameraEnabled: false,
            videoDimensions: .zero,
            creationTime: Date(),
            audioLevel: 0,
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView()))
    )
}
