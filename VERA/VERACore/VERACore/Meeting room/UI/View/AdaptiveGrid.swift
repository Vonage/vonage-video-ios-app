//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct AdaptiveGrid: View {

    let participants: [Participant]

    let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 16)
    ]

    let itemHeight: Double = 225
    let minItemWidth: Double = 300
    let spacing: Double = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in

                let availableWidth = geometry.size.width - spacing
                let itemsPerRow = max(1, Int((availableWidth + spacing) / (minItemWidth + spacing)))
                let availableHeight = geometry.size.height - spacing
                let rowsVisible = max(1, Int((availableHeight + spacing) / (itemHeight + spacing)))

                let maxVisibleItems = itemsPerRow * rowsVisible
                let takeCount =
                    maxVisibleItems >= participants.count
                    ? maxVisibleItems
                    : max(1, maxVisibleItems - 1)
                let visibleItems = Array(participants.prefix(takeCount))

                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    GridRow {
                        ForEach(visibleItems, id: \.id) { participant in
                            ParticipantVideoCard(participant: participant)
                                .frame(maxWidth: .infinity, minHeight: 200)
                        }
                        if participants.count > takeCount {
                            HiddenParticipantsTile(
                                participantNames:
                                    participants
                                    .suffix(participants.count - takeCount)
                                    .map { $0.name })
                        }
                    }
                }
                .animation(.easeInOut, value: participants)
                .frame(maxHeight: .infinity, alignment: .top)

            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AdaptiveGrid(participants: PreviewData.manyParticipants)
}
