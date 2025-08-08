//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

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
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(.vGray4.opacity(0.8))
                
                HStack(spacing: spacedBy) {
                    AvatarGroup(
                        users: participantNames.map {
                            AvatarGroupUser(name: $0)
                    },
                        maxVisible: 3,
                        size: min(geometry.size.width, geometry.size.height) * 0.10)
                }
                .padding(8)
                .background(.vGray4.opacity(0.8))
            }
            .aspectRatio(4/3, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.vGray4.opacity(0.8))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 2)
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
            .fill(.vGray4.opacity(0.8))
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
