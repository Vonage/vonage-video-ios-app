//
//  Created by Vonage on 6/8/25.
//

import SwiftUI
import VERACommonUI

struct HiddenParticipantsTile: View {
    let participantNames: [String]
    let spacedBy: CGFloat

    init(
        participantNames: [String],
        spacedBy: CGFloat = -8
    ) {
        self.participantNames = participantNames
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
            participantNames: [
                "Arthur Dent",
                "Ford Prefect",
                "Zaphod Beeblebrox",
                "Marvin",
            ]
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
