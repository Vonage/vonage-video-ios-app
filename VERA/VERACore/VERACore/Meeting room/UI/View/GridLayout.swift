//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

struct AdaptiveVideoGrid: View {
    let participants: [Participant]
    let activeSpeakerId: String?
    private let aspectRatio: Double = 16.0 / 9.0
    
    var body: some View {
        GeometryReader { geometry in
            if participants.isEmpty {
                EmptyStateView()
            } else {
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
                        .aspectRatio(aspectRatio, contentMode: .fit)
                    }
                }
                .padding(layout.padding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .animation(.easeInOut(duration: 0.3), value: participants.count)
    }
    
    // MARK: - Layout Calculation Algorithm
    
    private func calculateOptimalLayout(
        participantCount: Int,
        containerSize: CGSize
    ) -> GridLayout {
        guard participantCount > 0 else {
            return GridLayout(columns: [], spacing: 0, padding: 0)
        }
        
        // Special cases for better UX
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
                    GridItem(.flexible(), spacing: 8)
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
        let bestGrid = findOptimalGrid(
            participantCount: count,
            containerSize: containerSize
        )
        
        #if DEBUG
        print("👥 Participants: \(count) -> Grid: \(bestGrid.rows)x\(bestGrid.columns)")
        #endif
        
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: bestGrid.columns)
        
        return GridLayout(
            columns: columns,
            spacing: 8,
            padding: 16
        )
    }
    
    private func findOptimalGrid(
        participantCount: Int,
        containerSize: CGSize
    ) -> (rows: Int, columns: Int) {
        // Use predefined optimal grids for common cases
        let optimalGrid = getOptimalGridForCount(participantCount)
        
        // Verify the optimal grid fits in the container
        let cellWidth = (containerSize.width - 32 - Double(optimalGrid.columns - 1) * 8) / Double(optimalGrid.columns)
        let cellHeight = cellWidth / aspectRatio
        let totalHeight = Double(optimalGrid.rows) * cellHeight + Double(optimalGrid.rows - 1) * 8 + 32
        
        // If optimal grid fits, use it
        if totalHeight <= containerSize.height {
            return optimalGrid
        }
        
        // Otherwise, fallback to dynamic calculation with constraints
        return findBestFittingGrid(participantCount: participantCount, containerSize: containerSize)
    }
    
    private func getOptimalGridForCount(_ count: Int) -> (rows: Int, columns: Int) {
        switch count {
        case 1: return (1, 1)
        case 2: return (1, 2)
        case 3: return (2, 2)  // 2x2 with one empty
        case 4: return (2, 2)
        case 5: return (2, 3)  // 2x3 with one empty
        case 6: return (2, 3)
        case 7: return (3, 3)  // 3x3 with two empty
        case 8: return (3, 3)  // 3x3 with one empty
        case 9: return (3, 3)
        case 10: return (3, 4) // 3x4 with two empty
        case 11: return (3, 4) // 3x4 with one empty
        case 12: return (3, 4)
        case 13...16: return (4, 4)
        case 17...20: return (4, 5)
        case 21...25: return (5, 5)
        default:
            // For larger numbers, calculate square-ish grid
            let sqrt = Int(ceil(sqrt(Double(count))))
            let cols = sqrt
            let rows = Int(ceil(Double(count) / Double(cols)))
            return (rows, cols)
        }
    }
    
    private func findBestFittingGrid(
        participantCount: Int,
        containerSize: CGSize
    ) -> (rows: Int, columns: Int) {
        var bestGrid = (rows: 1, columns: participantCount)
        
        // Limit maximum columns to avoid single row layouts
        let maxColumns = min(participantCount, 6) // Max 6 columns
        
        for columns in 1...maxColumns {
            let rows = Int(ceil(Double(participantCount) / Double(columns)))
            
            // Calculate if this configuration fits
            let cellWidth = (containerSize.width - 32 - Double(columns - 1) * 8) / Double(columns)
            let cellHeight = cellWidth / aspectRatio
            let totalHeight = Double(rows) * cellHeight + Double(rows - 1) * 8 + 32
            
            // Skip if doesn't fit vertically
            guard totalHeight <= containerSize.height else { continue }
            
            // Prefer more square-like configurations
            let aspectRatioScore = 1.0 / (abs(Double(columns) - Double(rows)) + 1.0)
            
            // Calculate space utilization
            let usedArea = Double(participantCount) * cellWidth * cellHeight
            let totalArea = containerSize.width * containerSize.height
            let utilization = usedArea / totalArea
            
            // Combined score favoring square-ish grids
            let score = aspectRatioScore * 0.7 + utilization * 0.3
            
            // Update best grid
            let currentScore = 1.0 / (abs(Double(bestGrid.columns) - Double(bestGrid.rows)) + 1.0) * 0.7
            if score > currentScore {
                bestGrid = (rows: rows, columns: columns)
            }
        }
        
        return bestGrid
    }
}

struct GridLayout {
    let columns: [GridItem]
    let spacing: Double
    let padding: Double
}

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No participants")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AdaptiveVideoGrid(
        participants: PreviewData.manyParticipants,
        activeSpeakerId: nil)
}
