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
            if participants.count == 1, let participant = participants.first {
                ParticipantVideoCard(
                    participant: participant,
                    activeSpeakerId: activeSpeakerId
                )
                .id(participant.id + "_main")
                .frame(maxWidth: .infinity, minHeight: 200)
                .transition(.opacity)
            } else if participants.count > 1 {
                GeometryReader { geometry in
                    let layout = calculateOptimalLayout(
                        participantCount: participants.count,
                        containerSize: geometry.size
                    )

                    LazyVGrid(columns: layout.columns, spacing: layout.spacing) {
                        ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                            ParticipantVideoCard(
                                participant: participant,
                                activeSpeakerId: activeSpeakerId
                            )
                            .id("\(participant.id)_\(index)_\(participants.count)")
                            .if(layout.customCellSize != nil) { view in
                                view.frame(
                                    width: layout.customCellSize!.width,
                                    height: layout.customCellSize!.height
                                )
                                .clipped()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .animation(.easeInOut(duration: 0.4), value: participants.count)
        .animation(.easeInOut(duration: 0.3), value: horizontalSizeClass)
        .animation(.easeInOut(duration: 0.3), value: verticalSizeClass)
    }

    // MARK: - Space Maximization Algorithm

    private func calculateOptimalLayout(
        participantCount: Int,
        containerSize: CGSize
    ) -> GridLayout {
        guard participantCount > 0 else {
            return GridLayout(columns: [], spacing: 0, padding: 0, customCellSize: nil)
        }

        switch participantCount {
        case 1: return singleParticipantLayout()
        case 2: return twoParticipantLayout(containerSize: containerSize)
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
            padding: 16,
            customCellSize: nil
        )
    }

    private func twoParticipantLayout(containerSize: CGSize) -> GridLayout {
        let isLandscape = containerSize.width > containerSize.height

        if isLandscape {
            // Side by side with optimized spacing
            return GridLayout(
                columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                ],
                spacing: 6,
                padding: 12,
                customCellSize: nil
            )
        } else {
            // Stacked vertically with optimized spacing
            return GridLayout(
                columns: [GridItem(.flexible())],
                spacing: 6,
                padding: 12,
                customCellSize: nil
            )
        }
    }

    private func multiParticipantLayout(
        count: Int,
        containerSize: CGSize
    ) -> GridLayout {
        // Find the grid configuration that maximizes space usage
        let optimalGrid = findMaximumSpaceGrid(
            participantCount: count, containerSize: containerSize)

        // Create flexible columns - ParticipantVideoCard handles its own aspect ratio
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: optimalGrid.spacing),
            count: optimalGrid.columns)

        return GridLayout(
            columns: columns,
            spacing: optimalGrid.spacing,
            padding: optimalGrid.padding,
            customCellSize: CGSize(width: optimalGrid.cellWidth, height: optimalGrid.cellHeight)
        )
    }

    private func findMaximumSpaceGrid(
        participantCount: Int,
        containerSize: CGSize
    ) -> (
        rows: Int, columns: Int, cellWidth: Double, cellHeight: Double, spacing: Double, padding: Double,
        efficiency: Double
    ) {

        // Reduce spacing based on participant count for maximum space utilization
        let padding: Double = participantCount <= 4 ? 12 : 8
        let spacing: Double = participantCount <= 2 ? 6 : (participantCount <= 4 ? 4 : 2)

        let minCellWidth: Double = 100
        let minCellHeight: Double = 60

        var bestGrid:
            (
                rows: Int, columns: Int, cellWidth: Double, cellHeight: Double,
                spacing: Double, padding: Double, efficiency: Double
            )?

        // Try different grid configurations to find the one that maximizes space usage
        let maxReasonableColumns = min(participantCount, 6)  // Reasonable upper limit

        for columns in 1...maxReasonableColumns {
            let rows = Int(ceil(Double(participantCount) / Double(columns)))

            // Calculate available space for this grid configuration
            let availableWidth = containerSize.width - padding * 2 - Double(columns - 1) * spacing
            let availableHeight = containerSize.height - padding * 2 - Double(rows - 1) * spacing

            let cellWidth = availableWidth / Double(columns)
            let cellHeight = availableHeight / Double(rows)

            // Check if cells meet minimum size requirements
            guard cellWidth >= minCellWidth && cellHeight >= minCellHeight else {
                continue
            }

            // Calculate space efficiency (percentage of container used for video content)
            let usedWidth = Double(columns) * cellWidth + Double(columns - 1) * spacing + padding * 2
            let usedHeight = Double(rows) * cellHeight + Double(rows - 1) * spacing + padding * 2
            let efficiency = min(usedWidth / containerSize.width, usedHeight / containerSize.height)

            // Calculate actual video content percentage (excluding spacing and padding)
            let videoContentWidth = Double(columns) * cellWidth
            let videoContentHeight = Double(rows) * cellHeight
            let videoContentEfficiency =
                (videoContentWidth * videoContentHeight) / (containerSize.width * containerSize.height)

            // Bonus for more balanced aspect ratios (not too wide or too tall)
            let cellAspectRatio = cellWidth / cellHeight
            let aspectRatioBalance = 1.0 - abs(log2(cellAspectRatio)) / 3.0  // Penalize extreme ratios
            let balancedAspectRatioBonus = max(0, aspectRatioBalance) * 0.1

            // Bonus for using more of the available participants (fewer empty cells)
            let emptyCells = rows * columns - participantCount
            let utilizationBonus = (1.0 - Double(emptyCells) / Double(rows * columns)) * 0.05

            // Enhanced score prioritizing actual video content area
            let score = calculateGridScore(
                videoContentEfficiency: videoContentEfficiency,
                efficiency: efficiency,
                aspectRatioBalance: balancedAspectRatioBonus,
                utilizationBonus: utilizationBonus
            )

            let isCurrentBest: Bool
            if let existingBestGrid = bestGrid {
                let existingScore = calculateExistingGridScore(
                    bestGrid: existingBestGrid,
                    containerSize: containerSize,
                    participantCount: participantCount
                )
                isCurrentBest = score > existingScore
            } else {
                isCurrentBest = true
            }

            if isCurrentBest {
                bestGrid = (rows, columns, cellWidth, cellHeight, spacing, padding, efficiency)
            }
        }

        // Fallback if no valid grid found (should rarely happen with reduced minimums)
        guard let best = bestGrid else {
            let fallbackColumns = min(3, participantCount)
            let fallbackRows = Int(ceil(Double(participantCount) / Double(fallbackColumns)))
            return (fallbackRows, fallbackColumns, minCellWidth, minCellHeight, spacing, padding, 0.5)
        }

        return best
    }

    // MARK: - Grid Score Calculation Helpers

    private func calculateGridScore(
        videoContentEfficiency: Double,
        efficiency: Double,
        aspectRatioBalance: Double,
        utilizationBonus: Double
    ) -> Double {
        return videoContentEfficiency * 0.8 + efficiency * 0.2 + aspectRatioBalance + utilizationBonus
    }

    private func calculateExistingGridScore(
        bestGrid: (
            rows: Int, columns: Int, cellWidth: Double, cellHeight: Double, spacing: Double, padding: Double,
            efficiency: Double
        ),
        containerSize: CGSize,
        participantCount: Int
    ) -> Double {
        let videoContentEfficiency =
            (Double(bestGrid.columns) * bestGrid.cellWidth * Double(bestGrid.rows) * bestGrid.cellHeight)
            / (containerSize.width * containerSize.height)
        let aspectRatioBalance = (1.0 - abs(log2(bestGrid.cellWidth / bestGrid.cellHeight)) / 3.0) * 0.1
        let utilizationBonus =
            (1.0 - Double((bestGrid.rows * bestGrid.columns - participantCount))
                / Double(bestGrid.rows * bestGrid.columns)) * 0.05

        return calculateGridScore(
            videoContentEfficiency: videoContentEfficiency,
            efficiency: bestGrid.efficiency,
            aspectRatioBalance: aspectRatioBalance,
            utilizationBonus: utilizationBonus
        )
    }
}

struct GridLayout {
    let columns: [GridItem]
    let spacing: Double
    let padding: Double
    let customCellSize: CGSize?

    init(columns: [GridItem], spacing: Double, padding: Double, customCellSize: CGSize? = nil) {
        self.columns = columns
        self.spacing = spacing
        self.padding = padding
        self.customCellSize = customCellSize
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    AdaptiveGridLayout(
        participants: [],
        activeSpeakerId: String?.none
    )
    .frame(height: 400)
}
