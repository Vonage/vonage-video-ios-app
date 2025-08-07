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
                    .aspectRatio(participant.aspectRatio, contentMode: .fit) // ✅ Usa aspect ratio del stream
                    .clipped() // Asegura que no se desborde
                    .overlay(
                        // Overlay que no afecta el tamaño
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
                    )
            } else {
                ZStack {
                    VStack {
                        AvatarInitials(state: .init(userName: participant.name))
                            .padding(24)
                    }
                    .frame(minWidth: 160, minHeight: 120) // Tamaño mínimo para avatar
                    .aspectRatio(participant.aspectRatio, contentMode: .fit) // ✅ Consistencia visual
                    .background(.vGray4.opacity(0.8))
                    
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
            }
        }
        .background(.vGray4.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
        // 🔍 Debug overlay temporal
        .overlay(
            VStack(alignment: .leading, spacing: 2) {
                if let dimensions = participant.videoDimensions {
                    Text("📐 \(Int(dimensions.width))×\(Int(dimensions.height))")
                    Text("📏 \(String(format: "%.2f", participant.aspectRatio))")
                } else {
                    Text("📐 No dimensions")
                }
            }
            .font(.system(size: 8))
            .foregroundColor(.white)
            .background(Color.black.opacity(0.7))
            .padding(2),
            alignment: .topTrailing
        )
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
