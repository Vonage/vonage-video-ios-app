//
//  Created by Vonage on 23/7/25.
//

import AVKit
import SwiftUI
import VERACommonUI

struct ParticipantVideoCard: View {
    let participant: Participant
    let activeSpeakerId: String?

    private let containerAspectRatio: Double = 16.0 / 9.0
    var shouldFlipHorizontally: Bool { participant.isRemote && !participant.isScreenshare }

    var body: some View {
        Group {
            if participant.isCameraEnabled {
                ZStack {
                    Rectangle()
                        .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(0.8))
                        .aspectRatio(containerAspectRatio, contentMode: .fit)
                        .overlay(
                            ZStack {
                                if participant.isScreenshare {
                                    participant.view
                                        .aspectRatio(participant.aspectRatio, contentMode: .fit)
                                        .clipped()

                                    ParticipantVideoCardOverlays(
                                        isMicEnabled: participant.isMicEnabled,
                                        name: participant.name
                                    )
                                } else {
                                    participant.view
                                        .horizontallyFlipped(shouldFlipHorizontally)
                                        .aspectRatio(participant.aspectRatio, contentMode: .fit)
                                        .clipped()

                                    ParticipantVideoCardOverlays(
                                        isMicEnabled: participant.isMicEnabled,
                                        name: participant.name
                                    )
                                }
                            }
                        )
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(0.8))
                        .aspectRatio(containerAspectRatio, contentMode: .fit)
                        .overlay(
                            ZStack {
                                Rectangle()
                                    .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(0.8))
                                    .overlay(
                                        AvatarInitials(state: .init(userName: participant.name))
                                            .padding(24)
                                    ).aspectRatio(participant.aspectRatio, contentMode: .fit)
                                    .clipped()

                                ParticipantVideoCardOverlays(
                                    isMicEnabled: participant.isMicEnabled,
                                    name: participant.name
                                )
                            }
                        )
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
                    lineWidth: participant.id == activeSpeakerId ? 4 : 0)
        )
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
    var color: Color {
        isMicEnabled ? .white : VERACommonUIAsset.SemanticColors.error.swiftUIColor
    }

    var body: some View {
        MicIndicatorImage(isMicEnabled: isMicEnabled)
            .foregroundColor(color)
            .padding(6)
            .background {
                if #available(iOS 26.0, *) {
                    Circle()
                        .glassEffect(.regular)
                } else {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                }
            }
            .frame(width: 28, height: 28)
    }
}

struct MicIndicatorImage: View {
    var isMicEnabled: Bool

    var body: some View {
        if isMicEnabled {
            VERACommonUIAsset.Images.microphoneLine.swiftUIImage
        } else {
            VERACommonUIAsset.Images.micMuteLine.swiftUIImage
        }
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
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView())),
        activeSpeakerId: ""
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
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView())),
        activeSpeakerId: ""
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
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView())),
        activeSpeakerId: ""
    )
}
