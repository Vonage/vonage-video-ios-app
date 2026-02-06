//
//  Created by Vonage on 6/8/25.
//

import SwiftUI
import VERADomain

// MARK: - Layout Constants

/// Configuration constants for the Active Speaker layout.
///
/// These values control the visual appearance and behavior of the layout,
/// including tile sizing, spacing, and aspect ratios. Centralized here for
/// easy adjustment and consistency across all layout components.
enum ActiveSpeakerLayoutConstants {
    /// Standard 16:9 video aspect ratio
    static let aspectRatio: Double = 16.0 / 9.0
    /// Width ratio for the main/active speaker tile
    static let mainParticipantWidthRatio: Double = 0.70
    /// Width ratio for the sidebar containing other participants
    static let sidebarWidthRatio: Double = 0.30
    /// Default spacing between participant tiles
    static let spacing: Double = 8
    /// Minimum height for a single participant view
    static let minSingleParticipantHeight: Double = 200
    /// Bottom padding for the layout container
    static let bottomPadding: Double = 4
    /// Horizontal padding for the layout container
    static let horizontalPadding: Double = 12
}

// MARK: - Layout Info

/// Pre-calculated layout information for sidebar participant positioning.
///
/// This struct is computed based on available screen space and determines
/// how many participant tiles can be displayed before overflow handling kicks in.
/// Used by `SidebarParticipantsView` to render the appropriate number of tiles.
struct SidebarLayoutInfo {
    /// Number of participants that can be displayed in the sidebar
    let visibleCount: Int

    /// Total number of participants (excluding active speaker)
    let totalCount: Int

    /// Returns `true` if some participants will be collapsed into the overflow tile
    var hasHiddenParticipants: Bool {
        visibleCount < totalCount
    }
}

/// Layout orientation options based on device size class.
private enum LayoutOrientation {
    /// Horizontal layout with main speaker on left, sidebar on right (iPad/landscape)
    case horizontal
    /// Vertical layout with main speaker on top, others below (iPhone/portrait)
    case vertical
}

// MARK: - Active Speaker Layout

/// A video conferencing layout that emphasizes the current active speaker.
///
/// `ActiveSpeakerLayout` displays participants in a format optimized for meetings
/// where one person speaks at a time. The active speaker receives the largest tile
/// (70% width in horizontal mode), while other participants appear in a sidebar.
///
/// ## Layout Behavior
///
/// The layout automatically adapts based on device size class:
/// - **Horizontal** (iPad, landscape): Main speaker left, sidebar right
/// - **Vertical** (iPhone, portrait): Main speaker top, others bottom
///
/// ## Participant Overflow
///
/// When more participants exist than can fit in the sidebar, excess participants
/// are collapsed into a `HiddenParticipantsTile` showing their initials.
///
/// ## Video Stream Management
///
/// Uses `.trackingVisibility(of:)` modifier to optimize bandwidth:
/// - Visible participants have their video streams enabled via `onAppear`
/// - Hidden participants have streams disabled via `onDisappear`
///
/// ## Usage
///
/// ```swift
/// ActiveSpeakerLayout(
///     participants: meeting.participants,
///     activeSpeakerId: meeting.currentSpeakerId
/// )
/// ```
///
/// - Note: Avoid applying animations that could interfere with video rendering.
struct ActiveSpeakerLayout: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let participants: [Participant]
    let activeSpeakerId: String?

    /// Determines the preferred layout orientation based on device size classes
    private var preferredLayoutOrientation: LayoutOrientation {
        if verticalSizeClass == .compact {
            return .horizontal
        } else if horizontalSizeClass == .compact {
            return .vertical
        } else {
            return .horizontal
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let singleParticipant = participants.first, participants.count == 1 {
                ParticipantVideoCard(
                    participant: singleParticipant,
                    activeSpeakerId: activeSpeakerId
                )
                .id(singleParticipant.id + "_main_active")
                .frame(maxWidth: .infinity, minHeight: ActiveSpeakerLayoutConstants.minSingleParticipantHeight)
                .trackingVisibility(of: singleParticipant)
            } else if participants.count > 1 {
                Group {
                    switch preferredLayoutOrientation {
                    case .horizontal:
                        HorizontalActiveSpeakerLayoutView(
                            participants: participants,
                            activeSpeakerId: activeSpeakerId)
                    case .vertical:
                        VerticalActiveSpeakerLayoutView(
                            participants: participants,
                            activeSpeakerId: activeSpeakerId)
                    }
                }
                .transition(.identity)
            }
        }
        .padding(.bottom, ActiveSpeakerLayoutConstants.bottomPadding)
        .padding(.horizontal, ActiveSpeakerLayoutConstants.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Horizontal Layout

/// Horizontal variant of the active speaker layout for wider screens.
///
/// Displays the active speaker in a large tile on the left (70% width) with
/// remaining participants stacked vertically in a sidebar on the right (30% width).
/// Automatically calculates how many participants fit in the sidebar based on
/// available height and the 16:9 aspect ratio.
///
/// Used when:
/// - `verticalSizeClass == .compact` (landscape orientation)
/// - `horizontalSizeClass == .regular` (iPad)
struct HorizontalActiveSpeakerLayoutView: View {
    let participants: [Participant]
    let activeSpeakerId: String?

    private var activeParticipant: Participant? {
        participants.first
    }

    private var restOfParticipants: [Participant] {
        Array(participants.dropFirst())
    }

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 0 && geometry.size.height > 0,
                let activeParticipant = activeParticipant
            {
                let mainWidth = geometry.size.width * ActiveSpeakerLayoutConstants.mainParticipantWidthRatio
                let sidebarWidth = geometry.size.width * ActiveSpeakerLayoutConstants.sidebarWidthRatio
                let layoutInfo = calculateSidebarLayout(
                    sidebarWidth: sidebarWidth,
                    availableHeight: geometry.size.height,
                    participantCount: restOfParticipants.count
                )

                HStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
                    ParticipantVideoCard(
                        participant: activeParticipant,
                        activeSpeakerId: activeSpeakerId
                    )
                    .id(activeParticipant.id + "_main")
                    .frame(width: max(1, mainWidth))
                    .trackingVisibility(of: activeParticipant)

                    SidebarParticipantsView(
                        participants: restOfParticipants,
                        layoutInfo: layoutInfo,
                        activeSpeakerId: activeSpeakerId
                    )
                    .frame(width: max(1, sidebarWidth))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Layout Calculation

    /// Calculates how many participants can fit in the sidebar based on available space
    /// - Parameters:
    ///   - sidebarWidth: The available width for the sidebar
    ///   - availableHeight: The available height for the sidebar
    ///   - participantCount: The total number of participants to display
    /// - Returns: Layout information containing visible count
    private func calculateSidebarLayout(
        sidebarWidth: CGFloat,
        availableHeight: CGFloat,
        participantCount: Int
    ) -> SidebarLayoutInfo {
        guard sidebarWidth > 0, availableHeight > 0 else {
            return SidebarLayoutInfo(visibleCount: 0, totalCount: participantCount)
        }

        let spacing = ActiveSpeakerLayoutConstants.spacing
        let aspectRatio = ActiveSpeakerLayoutConstants.aspectRatio

        let cellWidth = max(1, sidebarWidth - spacing)
        let cellHeight = max(1, cellWidth / aspectRatio)
        let rowsVisible = max(1, Int((availableHeight + spacing) / (cellHeight + spacing)))

        // Reserve one slot for the "hidden participants" tile if needed
        let visibleCount: Int
        if rowsVisible >= participantCount {
            visibleCount = participantCount
        } else {
            visibleCount = max(1, rowsVisible - 1)
        }

        return SidebarLayoutInfo(visibleCount: visibleCount, totalCount: participantCount)
    }
}

// MARK: - Sidebar Participants View

/// Displays non-active participants in a vertical stack with overflow handling.
///
/// This component renders participant video cards based on pre-calculated layout
/// information. When more participants exist than can fit, excess participants
/// are collapsed into a `HiddenParticipantsTile` showing their initials.
///
/// ## Video Stream Optimization
///
/// - Visible participants: Video enabled via `.trackingVisibility(of:)`
/// - Hidden participants: Video disabled via `onDisappear` when tile appears
struct SidebarParticipantsView: View {
    let participants: [Participant]
    let layoutInfo: SidebarLayoutInfo
    let activeSpeakerId: String?

    private var visibleParticipants: [Participant] {
        Array(participants.prefix(layoutInfo.visibleCount))
    }

    private var hiddenParticipants: [Participant] {
        Array(participants.dropFirst(layoutInfo.visibleCount))
    }

    var body: some View {
        VStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
            ForEach(Array(visibleParticipants.enumerated()), id: \.element.id) { index, participant in
                ParticipantVideoCard(
                    participant: participant,
                    activeSpeakerId: activeSpeakerId
                )
                .id("\(participant.id)_\(index)_\(visibleParticipants.count)")
                .aspectRatio(ActiveSpeakerLayoutConstants.aspectRatio, contentMode: .fit)
                .trackingVisibility(of: participant)
            }

            if !hiddenParticipants.isEmpty {
                HiddenParticipantsTile(
                    participantNames: hiddenParticipants.map { $0.name }
                )
                .id("hidden_\(hiddenParticipants.count)_\(visibleParticipants.count)")
                .aspectRatio(ActiveSpeakerLayoutConstants.aspectRatio, contentMode: .fit)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Vertical Layout

/// Vertical variant of the active speaker layout for narrower screens.
///
/// Displays the active speaker in a large tile at the top with remaining
/// participants shown below in a horizontal arrangement. Supports up to
/// 2 visible non-active participants before collapsing to an overflow tile.
///
/// ## Participant Display Rules
///
/// - **1 other participant**: Single tile below main speaker
/// - **2 other participants**: Two tiles side-by-side below main speaker
/// - **3+ other participants**: One tile + overflow tile showing remaining count
///
/// Used when `horizontalSizeClass == .compact` (iPhone portrait).
struct VerticalActiveSpeakerLayoutView: View {
    let participants: [Participant]
    let activeSpeakerId: String?

    private var activeParticipant: Participant? {
        participants.first
    }

    private var restOfParticipants: [Participant] {
        Array(participants.dropFirst())
    }

    var body: some View {
        VStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
            if let activeParticipant = activeParticipant {
                ParticipantVideoCard(
                    participant: activeParticipant,
                    activeSpeakerId: activeSpeakerId
                )
                .id(activeParticipant.id + "_main")
                .trackingVisibility(of: activeParticipant)
            }

            Group {
                if restOfParticipants.count == 1 {
                    ParticipantVideoCard(
                        participant: restOfParticipants[0],
                        activeSpeakerId: activeSpeakerId
                    )
                    .id(restOfParticipants[0].id + "_other")
                    .trackingVisibility(of: restOfParticipants[0])
                } else if restOfParticipants.count == 2 {
                    HStack {
                        ParticipantVideoCard(
                            participant: restOfParticipants[0],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[0].id + "_other")
                        .trackingVisibility(of: restOfParticipants[0])

                        ParticipantVideoCard(
                            participant: restOfParticipants[1],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[1].id + "_other")
                        .trackingVisibility(of: restOfParticipants[1])
                    }
                    .transition(.slide)
                } else if restOfParticipants.count >= 3 {
                    HStack {
                        ParticipantVideoCard(
                            participant: restOfParticipants[0],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[0].id + "_other")
                        .trackingVisibility(of: restOfParticipants[0])

                        let hiddenParticipants = Array(restOfParticipants.dropFirst())
                        HiddenParticipantsTile(
                            participantNames: hiddenParticipants.map { $0.name }
                        )
                        .id("hidden_participants")
                        .transition(.opacity)
                    }
                    .transition(.slide)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ActiveSpeakerLayout(participants: [PreviewData.singleParticipant], activeSpeakerId: nil)
}

#Preview {
    ActiveSpeakerLayout(participants: PreviewData.twoParticipants, activeSpeakerId: nil)
}

#Preview {
    ActiveSpeakerLayout(participants: PreviewData.manyParticipants, activeSpeakerId: nil)
}
