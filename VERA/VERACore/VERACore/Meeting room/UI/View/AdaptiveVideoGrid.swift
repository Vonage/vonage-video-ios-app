//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

struct AdaptiveGridLayout: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let participants: [Participant]
    let activeSpeakerId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if participants.count == 1 {
                ParticipantVideoCard(
                    participant: participants.first!,
                    activeSpeakerId: activeSpeakerId
                )
                .id(participants.first!.id + "_main")
                .frame(maxWidth: .infinity, minHeight: 200)
                .transition(.opacity)
            } else if participants.count > 1 {
                GeometryReader { geometry in
                    let layout = calculateOptimalLayout(
                        participantCount: participants.count,
                        containerSize: geometry.size
                    )

                    let isLandscape = geometry.size.width > geometry.size.height
                    if isLandscape && participants.count > 2 {
                        LazyHGrid(rows: layout.columns, alignment: .center, spacing: layout.spacing) {
                            ForEach(participants, id: \.id) { participant in
                                ParticipantVideoCard(
                                    participant: participant,
                                    activeSpeakerId: activeSpeakerId
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        LazyVGrid(columns: layout.columns, spacing: layout.spacing) {
                            ForEach(participants, id: \.id) { participant in
                                ParticipantVideoCard(
                                    participant: participant,
                                    activeSpeakerId: activeSpeakerId
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.4), value: participants.count)
        .animation(.easeInOut(duration: 0.3), value: horizontalSizeClass)
        .animation(.easeInOut(duration: 0.3), value: verticalSizeClass)
    }

    // MARK: - Layout Calculation Algorithm

    private func calculateOptimalLayout(
        participantCount: Int,
        containerSize: CGSize
    ) -> GridLayout {
        guard participantCount > 0 else {
            return GridLayout(columns: [], spacing: 0, padding: 0)
        }

        switch participantCount {
        case 1:
            return singleParticipantLayout()
        case 2:
            return twoParticipantLayout(containerSize: containerSize)
        default:
            return multiParticipantLayout(
                count: participantCount,
                containerSize: containerSize
            )
        }
    }

    private func singleParticipantLayout() -> GridLayout {
        return GridLayout(
            columns: [GridItem(.flexible())],
            spacing: 0,
            padding: 16
        )
    }

    private func twoParticipantLayout(containerSize: CGSize) -> GridLayout {
        let isLandscape = containerSize.width > containerSize.height

        if isLandscape {
            // Side by side
            return GridLayout(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ],
                spacing: 8,
                padding: 16
            )
        } else {
            // Stacked vertically
            return GridLayout(
                columns: [GridItem(.flexible())],
                spacing: 8,
                padding: 16
            )
        }
    }

    private func multiParticipantLayout(
        count: Int,
        containerSize: CGSize
    ) -> GridLayout {
        let bestGrid = getOptimalGridForContainerAndCount(count, containerSize: containerSize)

        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: bestGrid.columns)

        return GridLayout(
            columns: columns,
            spacing: 8,
            padding: 16
        )
    }

    private func getOptimalGridForContainerAndCount(
        _ count: Int,
        containerSize: CGSize
    ) -> (rows: Int, columns: Int) {
        let containerAspectRatio = containerSize.width / containerSize.height
        let isPortrait = containerAspectRatio < 1.0

        if isPortrait {
            switch count {
            case 1: return (1, 1)
            case 2: return (2, 1)
            case 3: return (3, 1)
            case 4: return (4, 1)
            case 5: return (5, 1)
            case 6: return (3, 2)
            case 7: return (4, 2)
            case 8: return (4, 2)
            case 9: return (5, 2)
            case 10: return (4, 3)
            case 11: return (4, 3)
            case 12: return (4, 3)
            case 13...16: return (4, 4)
            case 17...20: return (5, 4)
            default:
                let sqrt = Int(ceil(sqrt(Double(count))))
                let cols = sqrt
                let rows = Int(ceil(Double(count) / Double(cols)))
                return (rows, cols)
            }
        } else {
            switch count {
            case 1: return (1, 1)
            case 2: return (1, 2)
            case 3: return (2, 2)
            case 4: return (2, 2)
            case 5: return (2, 3)
            case 6: return (2, 3)
            case 7: return (3, 3)
            case 8: return (3, 3)
            case 9: return (3, 3)
            case 10: return (3, 4)
            case 11: return (3, 4)
            case 12: return (3, 4)
            case 13...16: return (4, 4)
            case 17...20: return (4, 5)
            default:
                let sqrt = Int(ceil(sqrt(Double(count))))
                let cols = sqrt
                let rows = Int(ceil(Double(count) / Double(cols)))
                return (rows, cols)
            }
        }
    }
}

struct GridLayout {
    let columns: [GridItem]
    let spacing: Double
    let padding: Double
}

#Preview {
    AdaptiveGridLayout(
        participants: PreviewData.manyParticipants,
        activeSpeakerId: PreviewData.arthurDent.id
    )
    .frame(height: 400)
}

#Preview {
    AdaptiveGridLayout(
        participants: [
            PreviewData.arthurDent,
            PreviewData.eddie,
            PreviewData.hummaKavula,
            PreviewData.marvin,
        ],
        activeSpeakerId: PreviewData.arthurDent.id
    )
    .frame(height: 400)
}
