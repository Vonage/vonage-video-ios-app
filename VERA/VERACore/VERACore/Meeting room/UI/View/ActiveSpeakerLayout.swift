//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

struct ActiveSpeakerLayout: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let participants: [Participant]

    let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 16)
    ]

    let itemHeight: Double = 225
    let minItemWidth: Double = 300
    let spacing: Double = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if participants.isEmpty {

            } else if participants.count == 1 {
                ParticipantVideoCard(participant: participants.first!)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                if verticalSizeClass == .compact {
                    HorizontalActiveSpeakerLayoutView(participants: participants)
                } else if horizontalSizeClass == .compact {
                    VerticalActiveSpeakerLayoutView(participants: participants)
                } else {
                    HorizontalActiveSpeakerLayoutView(participants: participants)
                }
            }
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct HorizontalActiveSpeakerLayoutView: View {
    let itemHeight: Double = 200 * 3 / 4
    let minItemWidth: Double = 200
    let spacing: Double = 0

    var activeParticipant: Participant {
        participants.first!
    }
    var restOfParticipants: [Participant] {
        Array(participants.dropFirst())
    }

    let participants: [Participant]

    let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 16)
    ]

    public var body: some View {
        GeometryReader { outerGeometry in
            HStack(spacing: 8) {
                ParticipantVideoCard(participant: activeParticipant)
                    .frame(
                        width: outerGeometry.size.width * 0.70,
                    )
                GeometryReader { geometry in

                    let availableWidth = geometry.size.width - spacing
                    let itemsPerRow = max(1, Int((availableWidth + spacing) / (minItemWidth + spacing)))
                    let availableHeight = geometry.size.height - spacing
                    let rowsVisible = max(1, Int((availableHeight + spacing) / (itemHeight + spacing)))

                    let maxVisibleItems = itemsPerRow * rowsVisible
                    let takeCount =
                        maxVisibleItems >= restOfParticipants.count
                        ? maxVisibleItems
                        : max(1, maxVisibleItems - 1)
                    let visibleItems = Array(restOfParticipants.prefix(takeCount))
                    let hiddenItems = Array(restOfParticipants.dropFirst(takeCount))

                    LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
                        ForEach(visibleItems, id: \.id) { participant in
                            GridRow {
                                ParticipantVideoCard(participant: participant)
                            }
                            if !hiddenItems.isEmpty {
                                GridRow {
                                    HiddenParticipantsTile(
                                        participantNames: hiddenItems.map { $0.name })
                                }
                            }
                        }
                    }
                    .animation(.easeInOut, value: participants)
                    .frame(maxHeight: .infinity, alignment: .top)
                }.frame(width: outerGeometry.size.width * 0.30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct VerticalActiveSpeakerLayoutView: View {
    let itemHeight: Double = 200 * 3 / 4
    let minItemWidth: Double = 200
    let spacing: Double = 0

    var activeParticipant: Participant {
        participants.first!
    }
    var restOfParticipants: [Participant] {
        Array(participants.dropFirst())
    }

    let participants: [Participant]

    let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 16)
    ]

    public var body: some View {
        GeometryReader { outerGeometry in
            VStack(spacing: 8) {
                ParticipantVideoCard(participant: activeParticipant)
                GeometryReader { geometry in

                    let availableWidth = geometry.size.width - spacing
                    let itemsPerRow = max(1, Int((availableWidth + spacing) / (minItemWidth + spacing)))
                    let availableHeight = geometry.size.height - spacing
                    let rowsVisible = max(1, Int((availableHeight + spacing) / (itemHeight + spacing)))

                    let maxVisibleItems = itemsPerRow * rowsVisible
                    let takeCount =
                        maxVisibleItems >= restOfParticipants.count
                        ? maxVisibleItems
                        : max(1, maxVisibleItems - 1)
                    let visibleItems = Array(restOfParticipants.prefix(takeCount))
                    let hiddenItems = Array(restOfParticipants.dropFirst(takeCount))

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        GridRow {
                            ForEach(visibleItems, id: \.id) { participant in
                                ParticipantVideoCard(participant: participant)

                            }
                            if !hiddenItems.isEmpty {
                                HiddenParticipantsTile(
                                    participantNames: hiddenItems.map { $0.name })
                            }
                        }
                    }
                    .animation(.easeInOut, value: participants)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ActiveSpeakerLayout(participants: PreviewData.manyParticipants)
}
