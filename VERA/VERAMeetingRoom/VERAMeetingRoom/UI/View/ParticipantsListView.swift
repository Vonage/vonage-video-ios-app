//
//  Created by Vonage on 13/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Layout constants for the participants list panel.
private enum ParticipantsListViewConstants {
    /// Horizontal padding for the share link button.
    static let shareLinkHorizontalPadding: CGFloat = 12
    /// Vertical padding for the share link button.
    static let shareLinkVerticalPadding: CGFloat = 6
    /// Corner radius for the share link button.
    static let shareLinkCornerRadius: CGFloat = 6
    /// Background opacity for the meeting URL section.
    static let urlSectionBackgroundOpacity: Double = 0.1
    /// Spacing between avatar and participant name in a row.
    static let rowSpacing: CGFloat = 16
    /// Diameter of the participant avatar circle.
    static let avatarSize: CGFloat = 40
}

public struct ParticipantsListView: View {
    @Environment(\.meetingRoomTheme) private var theme
    let participants: [UIParticipant]
    let participantsCount: Int
    let roomName: String
    let meetingURL: URL?
    let onDismiss: () -> Void
    @State private var searchText: String = ""

    public init(
        participants: [UIParticipant],
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
        ScreenIdentifierContainer(MeetingRoomAccessibilityID.participantsListScreen) {
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
                            }.tint(theme.textSecondary)
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
        }
        .tint(theme.textSecondary)
        .presentationDetents([.medium, .large])
        .opaquePresentationBackground(theme.background)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Meeting URL Section

    private var meetingURLSection: some View {
        Group {
            if let meetingURL = meetingURL {
                HStack {
                    Text(meetingURL.absoluteString)
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    ShareLink(item: meetingURL) {
                        VERACommonUIAsset.Images.shareLine.swiftUIImage
                            .foregroundColor(theme.textSecondary)
                            .padding(.horizontal, ParticipantsListViewConstants.shareLinkHorizontalPadding)
                            .padding(.vertical, ParticipantsListViewConstants.shareLinkVerticalPadding)
                            .cornerRadius(ParticipantsListViewConstants.shareLinkCornerRadius)
                    }
                }
                .padding()

            } else {
                EmptyView()
            }
        }.background(Color.gray.opacity(ParticipantsListViewConstants.urlSectionBackgroundOpacity))
    }

    // MARK: - Participants List

    private var participantsList: some View {
        List {
            ForEach(participants.filtered(by: searchText), id: \.id) { participant in
                ParticipantRowView(participant: participant)
                    #if os(iOS)
                        .listRowSeparator(.hidden)
                    #endif
                    .listRowBackground(Color.clear)
            }
        }
        #if os(iOS)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search participant..."
            )
        #else
            .searchable(
                text: $searchText,
                placement: .automatic,
                prompt: "Search participant..."
            )
        #endif
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Participant Row View

struct ParticipantRowView: View {
    @Environment(\.meetingRoomTheme) private var theme
    let participant: UIParticipant
    var onTogglePin: ((String) -> Void)?

    var body: some View {
        HStack(spacing: ParticipantsListViewConstants.rowSpacing) {
            ParticipantAvatarView(participant: participant)

            Text(participant.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(theme.textSecondary)

            Spacer()

            if participant.canTogglePinState {
                Button {
                    participant.onTogglePin?()
                } label: {
                    (participant.isPinned
                        ? VERACommonUIAsset.Images.pin2OffSolid.swiftUIImage
                        : VERACommonUIAsset.Images.pin2Solid.swiftUIImage)
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(participant.isPinned ? "Unpin" : "Pin")
            }

            micIndicator
        }
    }

    var micIndicator: MicIndicator {
        .init(
            participantID: participant.id,
            isMicEnabled: participant.isMicEnabled,
            participantName: participant.name,
            onForceMute: participant.onForceMute,
            forceMuteAccessibilityIdentifier: MeetingRoomAccessibilityID.participantListForceMuteButton(participant.id)
        )
    }
}

// MARK: - Participant Avatar View

struct ParticipantAvatarView: View {
    let participant: UIParticipant

    var body: some View {
        Circle()
            .fill(participant.name.getParticipantColor())
            .frame(
                width: ParticipantsListViewConstants.avatarSize,
                height: ParticipantsListViewConstants.avatarSize
            )
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
        participants: PreviewData.uiManyParticipants,
        participantsCount: PreviewData.uiManyParticipants.count,
        roomName: "heart-of-gold",
        meetingURL: .init(string: "https://video.vonage.com/room/heart-of-gold")
    ) {}
}
