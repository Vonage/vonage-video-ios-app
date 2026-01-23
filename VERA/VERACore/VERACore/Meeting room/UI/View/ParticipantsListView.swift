//
//  Created by Vonage on 13/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

public struct ParticipantsListView: View {
    let participants: [Participant]
    let participantsCount: Int
    let roomName: String
    let meetingURL: URL?
    let onDismiss: () -> Void

    public init(
        participants: [Participant],
        participantsCount: Int,
        roomName: String,
        meetingURL: URL?,
        onDismiss: @escaping () -> Void
    ) {
        self.participants = participants
        self.participantsCount = participantsCount
        self.roomName = roomName
        self.meetingURL = meetingURL
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                meetingURLSection

                Divider()
                    .padding(.horizontal)

                participantsList
            }
            .navigationTitle(String(localized: "Participants (\(participantsCount))"))
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                        }.tint(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                    }
                #else
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                        }
                    }
                #endif
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Meeting URL Section

    private var meetingURLSection: some View {
        Group {
            if let meetingURL = meetingURL {
                HStack {
                    Text(meetingURL.absoluteString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    ShareLink(item: meetingURL) {
                        VERACommonUIAsset.Images.shareLine.swiftUIImage
                            .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .cornerRadius(6)
                    }
                }
                .padding()

            } else {
                EmptyView()
            }
        }.background(Color.gray.opacity(0.1))
    }

    // MARK: - Participants List

    private var participantsList: some View {
        List {
            ForEach(participants, id: \.id) { participant in
                ParticipantRowView(participant: participant)
                    #if os(iOS)
                        .listRowSeparator(.hidden)
                    #endif
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Participant Row View

struct ParticipantRowView: View {
    let participant: Participant

    var body: some View {
        HStack(spacing: 16) {
            ParticipantAvatarView(participant: participant)

            Text(participant.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            MicIndicatorImage(isMicEnabled: participant.isMicEnabled)
                .font(.caption)
                .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
        }
    }
}

// MARK: - Participant Avatar View

struct ParticipantAvatarView: View {
    let participant: Participant

    var body: some View {
        Circle()
            .fill(participant.name.getParticipantColor())
            .frame(width: 40, height: 40)
            .overlay {
                Text(participant.name.getInitials())
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
    }
}

#Preview {
    ParticipantsListView(
        participants: PreviewData.manyParticipants,
        participantsCount: PreviewData.manyParticipants.count,
        roomName: "heart-of-gold",
        meetingURL: .init(string: "https://video.vonage.com/room/heart-of-gold")
    ) {}
}
