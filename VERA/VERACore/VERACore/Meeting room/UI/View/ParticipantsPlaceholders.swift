//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

struct ParticipantsPlaceholders: View {
    let participantNames: [String]
    let maxVisiblePlaceholders: Int
    let spacedBy: CGFloat

    init(
        participantNames: [String],
        maxVisiblePlaceholders: Int = 2,
        spacedBy: CGFloat = -8
    ) {
        self.participantNames = participantNames
        self.maxVisiblePlaceholders = maxVisiblePlaceholders
        self.spacedBy = spacedBy
    }

    var body: some View {
        let visiblePlaceholders = Array(participantNames.prefix(maxVisiblePlaceholders))
        let additionalCount = participantNames.count - maxVisiblePlaceholders

        ZStack(alignment: .center) {
            HStack(spacing: spacedBy) {
                ForEach(Array(visiblePlaceholders.enumerated()), id: \.offset) { index, participant in
                    AvatarInitials(state: .init(userName: participant))
                        .zIndex(Double(visiblePlaceholders.count - index))
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: 2)
                        )
                }

                if additionalCount > 0 {
                    AdditionalParticipantsAvatar(count: additionalCount)
                        .zIndex(0)
                }
            }
            .padding(8)
            .background(.vGray4.opacity(0.8))
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.uiSystemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
        .aspectRatio(4 / 3, contentMode: .fit)
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
            .fill(Color.gray)
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
        ParticipantsPlaceholders(
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
