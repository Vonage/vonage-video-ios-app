//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

/// Layout constants for the adaptive participant grid.
private enum AdaptiveGridLayoutConstants {
    /// Minimum height for a single-participant card.
    static let singleParticipantMinHeight: CGFloat = 200
    /// Bottom padding below the grid content.
    static let bottomPadding: CGFloat = 4
    /// Horizontal padding around the grid content.
    static let horizontalPadding: CGFloat = 12
    /// Padding for a single-participant layout.
    static let singleParticipantPadding: Double = 16
    /// Padding for layouts with two participants.
    static let twoParticipantPadding: Double = 12
    /// Spacing between cells in a two-participant layout.
    static let twoParticipantSpacing: Double = 6
    /// Padding threshold for ≤ 4 participants in multi-layout.
    static let fewParticipantsPadding: Double = 12
    /// Padding for > 4 participants in multi-layout.
    static let manyParticipantsPadding: Double = 8
    /// Spacing for ≤ 2 participants in multi-layout.
    static let fewParticipantsSpacing: Double = 6
    /// Spacing for 3–4 participants in multi-layout.
    static let mediumParticipantsSpacing: Double = 4
    /// Spacing for > 4 participants in multi-layout.
    static let manyParticipantsSpacing: Double = 2
    /// Minimum allowed cell width.
    static let minCellWidth: Double = 100
    /// Minimum allowed cell height.
    static let minCellHeight: Double = 60
    /// Maximum number of columns to try.
    static let maxReasonableColumns: Int = 6
    /// Fallback number of columns when no valid grid is found.
    static let fallbackColumns: Int = 3
    /// Fallback efficiency when no valid grid is found.
    static let fallbackEfficiency: Double = 0.5
    /// Divisor for aspect ratio penalty calculation.
    static let aspectRatioPenaltyDivisor: Double = 3.0
    /// Multiplier for balanced aspect ratio bonus.
    static let aspectRatioBonusMultiplier: Double = 0.1
    /// Multiplier for cell utilization bonus.
    static let utilizationBonusMultiplier: Double = 0.05
    /// Weight for video content efficiency in scoring.
    static let videoContentWeight: Double = 0.8
    /// Weight for overall efficiency in scoring.
    static let overallEfficiencyWeight: Double = 0.2
}

struct AdaptiveGridLayout: View {
    let participants: [UIParticipant]
    let activeSpeakerId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if participants.count == 1, let participant = participants.first {
                ParticipantVideoCard(
                    participant: participant,
                    activeSpeakerId: activeSpeakerId
                )
                .id(participant.id)
                .frame(maxWidth: .infinity, minHeight: AdaptiveGridLayoutConstants.singleParticipantMinHeight)
                .transition(.opacity)
            } else if participants.count > 1 {
                GeometryReader { geometry in
                    let layout = calculateOptimalLayout(
                        participantCount: participants.count,
                        containerSize: geometry.size
                    )

                    LazyVGrid(columns: layout.columns, spacing: layout.spacing) {
                        ForEach(participants, id: \.id) { participant in
                            ParticipantVideoCard(
                                participant: participant,
                                activeSpeakerId: activeSpeakerId
                            )
                            .id(participant.id)
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
        .padding(.bottom, AdaptiveGridLayoutConstants.bottomPadding)
        .padding(.horizontal, AdaptiveGridLayoutConstants.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            participants.forEach { $0.participant.onAppear?() }
        }
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
            padding: AdaptiveGridLayoutConstants.singleParticipantPadding,
            customCellSize: nil
        )
    }

    private func twoParticipantLayout(containerSize: CGSize) -> GridLayout {
        let isLandscape = containerSize.width > containerSize.height

        if isLandscape {
            // Side by side with optimized spacing
            return GridLayout(
                columns: [
                    GridItem(.flexible(), spacing: AdaptiveGridLayoutConstants.twoParticipantSpacing),
                    GridItem(.flexible(), spacing: AdaptiveGridLayoutConstants.twoParticipantSpacing),
                ],
                spacing: AdaptiveGridLayoutConstants.twoParticipantSpacing,
                padding: AdaptiveGridLayoutConstants.twoParticipantPadding,
                customCellSize: nil
            )
        } else {
            // Stacked vertically with optimized spacing
            return GridLayout(
                columns: [GridItem(.flexible())],
                spacing: AdaptiveGridLayoutConstants.twoParticipantSpacing,
                padding: AdaptiveGridLayoutConstants.twoParticipantPadding,
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
        let padding: Double =
            participantCount <= 4
            ? AdaptiveGridLayoutConstants.fewParticipantsPadding
            : AdaptiveGridLayoutConstants.manyParticipantsPadding
        let spacing: Double =
            participantCount <= 2
            ? AdaptiveGridLayoutConstants.fewParticipantsSpacing
            : (participantCount <= 4
                ? AdaptiveGridLayoutConstants.mediumParticipantsSpacing
                : AdaptiveGridLayoutConstants.manyParticipantsSpacing)

        let minCellWidth: Double = AdaptiveGridLayoutConstants.minCellWidth
        let minCellHeight: Double = AdaptiveGridLayoutConstants.minCellHeight

        var bestGrid:
            (
                rows: Int, columns: Int, cellWidth: Double, cellHeight: Double,
                spacing: Double, padding: Double, efficiency: Double
            )?

        // Try different grid configurations to find the one that maximizes space usage
        let maxReasonableColumns = min(participantCount, AdaptiveGridLayoutConstants.maxReasonableColumns)

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
            let aspectRatioBalance =
                1.0 - abs(log2(cellAspectRatio)) / AdaptiveGridLayoutConstants.aspectRatioPenaltyDivisor
            let balancedAspectRatioBonus =
                max(0, aspectRatioBalance) * AdaptiveGridLayoutConstants.aspectRatioBonusMultiplier

            // Bonus for using more of the available participants (fewer empty cells)
            let emptyCells = rows * columns - participantCount
            let utilizationBonus =
                (1.0 - Double(emptyCells) / Double(rows * columns))
                * AdaptiveGridLayoutConstants.utilizationBonusMultiplier

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
            let fallbackColumns = min(AdaptiveGridLayoutConstants.fallbackColumns, participantCount)
            let fallbackRows = Int(ceil(Double(participantCount) / Double(fallbackColumns)))
            return (
                fallbackRows, fallbackColumns, minCellWidth, minCellHeight, spacing, padding,
                AdaptiveGridLayoutConstants.fallbackEfficiency
            )
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
        return videoContentEfficiency * AdaptiveGridLayoutConstants.videoContentWeight
            + efficiency * AdaptiveGridLayoutConstants.overallEfficiencyWeight
            + aspectRatioBalance + utilizationBonus
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
        let aspectRatioBalance =
            (1.0 - abs(log2(bestGrid.cellWidth / bestGrid.cellHeight))
                / AdaptiveGridLayoutConstants.aspectRatioPenaltyDivisor)
            * AdaptiveGridLayoutConstants.aspectRatioBonusMultiplier
        let utilizationBonus =
            (1.0 - Double((bestGrid.rows * bestGrid.columns - participantCount))
                / Double(bestGrid.rows * bestGrid.columns))
            * AdaptiveGridLayoutConstants.utilizationBonusMultiplier

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

#Preview {
    AdaptiveGridLayout(
        participants: [],
        activeSpeakerId: String?.none
    )
    .frame(height: 400)
}
