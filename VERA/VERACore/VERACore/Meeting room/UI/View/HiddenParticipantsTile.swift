//
//  Created by Vonage on 6/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// A tile that displays avatars for participants who are hidden from the main video layout.
///
/// This component manages video stream visibility for hidden participants:
/// - When the tile appears, `onDisappear` is called on each participant to disable their video streams
/// - When the tile disappears (participants become visible again), `onAppear` is called to re-enable streams
///
/// This ensures bandwidth is not wasted on video streams for participants not currently visible.
struct HiddenParticipantsTile: View {
    let participants: [Participant]
    let spacedBy: CGFloat

    private var participantNames: [String] {
        participants.map { $0.name }
    }

    init(
        participants: [Participant],
        spacedBy: CGFloat = -8
    ) {
        self.participants = participants
        self.spacedBy = spacedBy
    }

    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(0.8))
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .overlay(
                    AvatarGroup(
                        users: participantNames.map {
                            AvatarGroupUser(name: $0)
                        },
                        maxVisible: 3,
                        size: 42
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
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

    init(count: Int, size: CGFloat = 96) {
        self.count = count
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(0.8))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
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
        HiddenParticipantsTile(
            participants: [
                PreviewData.arthurDent,
                PreviewData.eddie,
                PreviewData.fordPrefect,
                PreviewData.fenchurch,
            ]
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
