//
//  Created by Vonage on 6/8/25.
//

import SwiftUI
import VERACommonUI

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
    /// Fraction of available height allocated to the screen share tile in a split layout
    static let screenShareHeightRatio: Double = 0.65
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
/// The layout automatically adapts based on device size class and session state:
/// - **Screen sharing active** — The screen share tile takes the full available space.
///   If a participant is also pinned, the screen share appears on top (65%) with the
///   pinned participant below (35%); no sidebar is shown.
/// - **Horizontal** (iPad, landscape): Main speaker left, sidebar right
/// - **Vertical** (iPhone, portrait): Main speaker top, others below
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

    let participants: [UIParticipant]
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

    /// The first screen sharing participant, if any.
    private var screenShareParticipant: UIParticipant? {
        participants.first(where: { $0.isScreenshare })
    }

    /// The first pinned participant that is not a screen share, if any.
    /// Used alongside `screenShareParticipant` to build the split-screen layout.
    private var firstNonScreenSharePinnedParticipant: UIParticipant? {
        participants.first(where: { $0.isPinned && !$0.isScreenshare })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let screenShare = screenShareParticipant {
                ScreenShareLayoutView(
                    screenShareParticipant: screenShare,
                    pinnedParticipant: firstNonScreenSharePinnedParticipant,
                    activeSpeakerId: activeSpeakerId
                )
            } else if let singleParticipant = participants.first, participants.count == 1 {
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
    let participants: [UIParticipant]
    let activeSpeakerId: String?

    private func isParticipantProminent(_ participant: UIParticipant) -> Bool {
        participant.isProminent || participant.id == activeSpeakerId
    }

    /// Dynamically collects up to 3 prominent participants for the main viewing area.
    private var mainAreaParticipants: [UIParticipant] {
        guard let first = participants.first else { return [] }
        var result = [first]

        // Scan the rest of the array (bypassing the injected local participant if it's not prominent)
        let others = participants.dropFirst().filter { isParticipantProminent($0) }
        result.append(contentsOf: others.prefix(2))
        return result
    }

    /// The remaining participants that will be shown in the sidebar.
    private var restOfParticipants: [UIParticipant] {
        guard !participants.isEmpty else { return [] }
        let mainIds = Set(mainAreaParticipants.map { $0.id })
        // Preserve original ordering for the sidebar
        return participants.filter { !mainIds.contains($0.id) }
    }

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 0 && geometry.size.height > 0,
                !mainAreaParticipants.isEmpty
            {
                let mainWidth = geometry.size.width * ActiveSpeakerLayoutConstants.mainParticipantWidthRatio
                let sidebarWidth = geometry.size.width * ActiveSpeakerLayoutConstants.sidebarWidthRatio
                let layoutInfo = calculateSidebarLayout(
                    sidebarWidth: sidebarWidth,
                    availableHeight: geometry.size.height,
                    participantCount: restOfParticipants.count
                )

                HStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
                    VStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
                        ForEach(mainAreaParticipants, id: \.id) { participant in
                            ParticipantVideoCard(
                                participant: participant,
                                activeSpeakerId: activeSpeakerId
                            )
                            .id(participant.id + "_main")
                            .trackingVisibility(of: participant)
                        }
                    }
                    .frame(width: max(1, mainWidth))

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
    let participants: [UIParticipant]
    let layoutInfo: SidebarLayoutInfo
    let activeSpeakerId: String?

    private var visibleParticipants: [UIParticipant] {
        Array(participants.prefix(layoutInfo.visibleCount))
    }

    private var hiddenParticipants: [UIParticipant] {
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
                    participants: hiddenParticipants
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
    let participants: [UIParticipant]
    let activeSpeakerId: String?

    private func isParticipantProminent(_ participant: UIParticipant) -> Bool {
        participant.isProminent || participant.id == activeSpeakerId
    }

    /// Dynamically collects up to 3 prominent participants for the main viewing area.
    private var mainAreaParticipants: [UIParticipant] {
        guard let first = participants.first else { return [] }
        var result = [first]

        let others = participants.dropFirst().filter { isParticipantProminent($0) }
        result.append(contentsOf: others.prefix(2))
        return result
    }

    /// The remaining participants that will be shown in the sidebar equivalent.
    private var restOfParticipants: [UIParticipant] {
        guard !participants.isEmpty else { return [] }
        let mainIds = Set(mainAreaParticipants.map { $0.id })
        return participants.filter { !mainIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
            // Main Prominent Area
            ForEach(mainAreaParticipants, id: \.id) { participant in
                ParticipantVideoCard(
                    participant: participant,
                    activeSpeakerId: activeSpeakerId
                )
                .id(participant.id + "_main")
                .trackingVisibility(of: participant)
            }

            // Sidebar / Secondary Area
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
                            participants: hiddenParticipants
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

// MARK: - Screen Share Layout

/// A layout that displays screen sharing as the sole primary content.
///
/// ## Layout variants
///
/// - **Screen share only** (no pinned participant): The screen share tile fills the entire
///   available space. The video letterboxes to its native aspect ratio inside the tile.
/// - **Screen share + pinned participant**: A vertical split where the screen share occupies
///   the top 65% and the pinned participant occupies the remaining 35%. No sidebar is shown
///   regardless of how many other participants are in the session.
///
/// Only the **first** pinned non-screenshare participant is shown. If multiple participants
/// are pinned, only the top-priority one appears next to the screen share.
struct ScreenShareLayoutView: View {
    let screenShareParticipant: UIParticipant
    /// The first non-screenshare pinned participant to display alongside the screen share,
    /// or `nil` if no participant is pinned.
    let pinnedParticipant: UIParticipant?
    let activeSpeakerId: String?

    var body: some View {
        if let pinned = pinnedParticipant {
            GeometryReader { geometry in
                let screenShareHeight = max(
                    1,
                    (geometry.size.height - ActiveSpeakerLayoutConstants.spacing)
                        * ActiveSpeakerLayoutConstants.screenShareHeightRatio
                )
                VStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
                    ParticipantVideoCard(
                        participant: screenShareParticipant,
                        activeSpeakerId: activeSpeakerId,
                        applyAspectRatio: false
                    )
                    .id(screenShareParticipant.id + "_screenshare")
                    .frame(height: screenShareHeight)
                    .trackingVisibility(of: screenShareParticipant)

                    ParticipantVideoCard(
                        participant: pinned,
                        activeSpeakerId: activeSpeakerId,
                        applyAspectRatio: false
                    )
                    .id(pinned.id + "_pinned")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .trackingVisibility(of: pinned)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ParticipantVideoCard(
                participant: screenShareParticipant,
                activeSpeakerId: activeSpeakerId,
                applyAspectRatio: false
            )
            .id(screenShareParticipant.id + "_screenshare")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .trackingVisibility(of: screenShareParticipant)
        }
    }
}

#Preview {
    ActiveSpeakerLayout(participants: [PreviewData.uiSingleParticipant], activeSpeakerId: nil)
}

#Preview {
    ActiveSpeakerLayout(participants: PreviewData.uiTwoParticipants, activeSpeakerId: nil)
}

#Preview {
    ActiveSpeakerLayout(participants: PreviewData.uiManyParticipants, activeSpeakerId: nil)
}
