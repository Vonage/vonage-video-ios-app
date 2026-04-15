//
//  Created by Vonage on 6/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Layout constants for the hidden participants tile.
private enum HiddenParticipantsTileConstants {
    /// Default overlap spacing between stacked avatars.
    static let defaultAvatarSpacing: CGFloat = -8
    /// Background fill opacity.
    static let backgroundOpacity: Double = 0.8
    /// Aspect ratio width component for the tile (16:9).
    static let aspectRatioWidth: CGFloat = 16.0
    /// Aspect ratio height component for the tile (16:9).
    static let aspectRatioHeight: CGFloat = 9.0
    /// Maximum number of visible avatars in the group.
    static let maxVisibleAvatars: Int = 3
    /// Avatar size within the hidden participants tile.
    static let avatarSize: CGFloat = 42
    /// Corner radius of the tile.
    static let cornerRadius: CGFloat = 8
    /// Shadow radius around the tile.
    static let shadowRadius: CGFloat = 2
    /// Default size of the additional participants avatar circle.
    static let additionalAvatarDefaultSize: CGFloat = 96
    /// Stroke width for the additional participants circle border.
    static let additionalAvatarStrokeWidth: CGFloat = 2
}

/// A tile that displays avatars for participants who are hidden from the main video layout.
///
/// This component manages video stream visibility for hidden participants:
/// - When the tile appears, `onDisappear` is called on each participant to disable their video streams
/// - When the tile disappears (participants become visible again), `onAppear` is called to re-enable streams
///
/// This ensures bandwidth is not wasted on video streams for participants not currently visible.
struct HiddenParticipantsTile: View {
    let participants: [UIParticipant]
    let spacedBy: CGFloat

    private var participantNames: [String] {
        participants.map { $0.name }
    }

    init(
        participants: [UIParticipant],
        spacedBy: CGFloat = HiddenParticipantsTileConstants.defaultAvatarSpacing
    ) {
        self.participants = participants
        self.spacedBy = spacedBy
    }

    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(
                    VERACommonUIAsset.Colors.vGray4.swiftUIColor
                        .opacity(HiddenParticipantsTileConstants.backgroundOpacity)
                )
                .aspectRatio(
                    HiddenParticipantsTileConstants.aspectRatioWidth
                        / HiddenParticipantsTileConstants.aspectRatioHeight,
                    contentMode: .fit
                )
                .overlay(
                    AvatarGroup(
                        users: participantNames.map {
                            AvatarGroupUser(name: $0)
                        },
                        maxVisible: HiddenParticipantsTileConstants.maxVisibleAvatars,
                        size: HiddenParticipantsTileConstants.avatarSize
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: HiddenParticipantsTileConstants.cornerRadius))
        .shadow(radius: HiddenParticipantsTileConstants.shadowRadius)
        .onAppear {
            // Disable video streams for hidden participants.
            // Re-enabling is handled by ParticipantVideoCard's .trackingVisibility(of:)
            // when participants transition back to a visible state.
            for participant in participants {
                participant.onDisappear?()
            }
        }
    }
}

struct AdditionalParticipantsAvatar: View {
    let count: Int
    let size: CGFloat

    init(count: Int, size: CGFloat = HiddenParticipantsTileConstants.additionalAvatarDefaultSize) {
        self.count = count
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor
                .opacity(HiddenParticipantsTileConstants.backgroundOpacity))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: HiddenParticipantsTileConstants.additionalAvatarStrokeWidth)
            )
            .overlay(
                Text("+\(count)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Preview
struct ParticipantsPlaceholders_Previews: PreviewProvider {
    static var previews: some View {
        HiddenParticipantsTile(participants: PreviewData.uiManyParticipants)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
