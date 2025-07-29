//
//  Created by Vonage on 23/7/25.
//

import AVKit
import SwiftUI

struct ParticipantVideoCard: View {

    let participant: Participant

    var body: some View {
        ZStack(alignment: .center) {
            if participant.isCameraEnabled {
                participant.view
                    .id(participant.id + "_view")
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .edgesIgnoringSafeArea(.all)
                    .background(.vGray4.opacity(0.8))
            } else {
                VStack {
                    AvatarInitials(state: .init(userName: participant.name))
                        .padding(24)
                }
                .id(participant.id + "_initials")
                .background(.vGray4.opacity(0.8))
            }

            VStack {
                HStack {
                    Spacer()
                    MicIndicator(isMicEnabled: participant.isMicEnabled)
                }
                Spacer()
                HStack {
                    NameLabel(name: participant.name)
                    Spacer()
                }
            }
            .padding(8)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.uiSystemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
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
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
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
            view: AnyView(EmptyView()))
    )
}
