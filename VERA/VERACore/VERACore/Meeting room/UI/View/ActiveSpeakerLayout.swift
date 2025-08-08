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
            if participants.count == 1 {
                ParticipantVideoCard(participant: participants.first!)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if participants.count > 1 {
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
    let spacing: Double = 8
    private let aspectRatio: Double = 16.0 / 9.0

    var activeParticipant: Participant {
        participants.first!
    }
    var restOfParticipants: [Participant] {
        Array(participants.dropFirst())
    }

    let participants: [Participant]

    let columns = [
        GridItem(.flexible(), spacing: 8)
    ]

    public var body: some View {
        GeometryReader { outerGeometry in
            HStack(spacing: 8) {
                ParticipantVideoCard(participant: activeParticipant)
                    .frame(width: outerGeometry.size.width * 0.70)
                
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let availableHeight = geometry.size.height
                    
                    let cellWidth = availableWidth - spacing
                    let cellHeight = cellWidth / aspectRatio
                    

                    let rowsVisible = max(1, Int((availableHeight + spacing) / (cellHeight + spacing)))
                    
                    let maxVisibleItems = rowsVisible
                    
                    let takeCount = maxVisibleItems >= restOfParticipants.count
                        ? restOfParticipants.count
                        : max(1, maxVisibleItems - 1)
                    
                    let visibleItems = Array(restOfParticipants.prefix(takeCount))
                    let hiddenItems = Array(restOfParticipants.dropFirst(takeCount))

                    LazyVGrid(columns: columns, alignment: .center, spacing: spacing) {
                        ForEach(visibleItems, id: \.id) { participant in
                            ParticipantVideoCard(participant: participant)
                                .aspectRatio(aspectRatio, contentMode: .fit)
                        }
                        
                        if !hiddenItems.isEmpty {
                            HiddenParticipantsTile(
                                participantNames: hiddenItems.map { $0.name }
                            )
                            .aspectRatio(aspectRatio, contentMode: .fit)
                        }
                    }
                    .animation(.easeInOut, value: participants.count)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(width: outerGeometry.size.width * 0.30)
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
        VStack(spacing: 8) {
            ParticipantVideoCard(participant: activeParticipant)
            if restOfParticipants.count == 1 {
                ParticipantVideoCard(participant: restOfParticipants[0])
            } else if restOfParticipants.count == 2 {
                HStack {
                    ParticipantVideoCard(participant: restOfParticipants[0])
                    ParticipantVideoCard(participant: restOfParticipants[1])
                }
            } else if restOfParticipants.count >= 3 {
                HStack {
                    ParticipantVideoCard(participant: restOfParticipants[0])
                    HiddenParticipantsTile(
                        participantNames: Array(restOfParticipants.dropFirst())
                            .map { $0.name })
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ActiveSpeakerLayout(participants: [PreviewData.singleParticipant])
}

#Preview {
    ActiveSpeakerLayout(participants: PreviewData.twoParticipants)
}

#Preview {
    ActiveSpeakerLayout(participants: PreviewData.manyParticipants)
}
