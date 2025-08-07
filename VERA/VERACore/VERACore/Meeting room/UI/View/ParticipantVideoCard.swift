//
//  Created by Vonage on 23/7/25.
//

import AVKit
import SwiftUI

struct ParticipantVideoCard: View {
    let participant: Participant

    var body: some View {
        Group {
            if participant.isCameraEnabled {
                participant.view
                    .scaleEffect(x: participant.isRemote ? -1 : 1, y: 1)
                    .aspectRatio(participant.aspectRatio, contentMode: .fit)
                    .clipped()
                    .overlay(
                        ParticipantVideoCardOverlays(
                            isMicEnabled: participant.isMicEnabled,
                            name: participant.name)
                    )
            } else {
                ZStack {
                    VStack {
                        AvatarInitials(state: .init(userName: participant.name))
                            .padding(24)
                    }
                    .frame(minWidth: 160, minHeight: 120)
                    .aspectRatio(participant.aspectRatio, contentMode: .fit)
                    .background(.vGray4.opacity(0.8))

                    ParticipantVideoCardOverlays(
                        isMicEnabled: participant.isMicEnabled,
                        name: participant.name)
                }
            }
        }
        .background(.vGray4.opacity(0.8))
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
            view: AnyView(EmptyView()))
    )
}

#Preview {
    ParticipantVideoCard(
        participant: Participant(
            id: "",
            name: "name",
            isMicEnabled: true,
            isCameraEnabled: false,
            videoDimensions: .zero,
            view: AnyView(EmptyView()))
    )
}
