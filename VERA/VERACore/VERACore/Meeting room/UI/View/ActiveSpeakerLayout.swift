//
//  Created by Vonage on 6/8/25.
//

import SwiftUI
import VERADomain

// MARK: - Layout Constants

/// Constants used for active speaker layout calculations
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
}

/// Represents the preferred layout orientation based on device size class
private enum LayoutOrientation {
    case horizontal
    case vertical
}

/// Main layout view for displaying participants in an active speaker format
///
/// `ActiveSpeakerLayout` provides an adaptive interface that automatically switches between
/// horizontal and vertical layouts based on SwiftUI's environment size classes. The layout
/// intelligently calculates available space to determine how many participants can be displayed,
/// automatically collapsing excess participants into a summary tile showing their initials.
///
/// Uses `onAppear` and `onDisappear` callbacks to activate or deactivate participant video streams.
/// When a participant becomes visible, `onAppear` enables their video stream.
/// When a participant is hidden, `onDisappear` disables their video stream to optimize bandwidth.
///
/// Be careful with animations, it may impact video rendering
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
        .padding(.bottom, 4)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

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
        GeometryReader { outerGeometry in
            if outerGeometry.size.width > 0 && outerGeometry.size.height > 0,
               let activeParticipant = activeParticipant {
                HStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
                    ParticipantVideoCard(
                        participant: activeParticipant,
                        activeSpeakerId: activeSpeakerId
                    )
                    .id(activeParticipant.id + "_main")
                    .frame(width: max(1, outerGeometry.size.width * ActiveSpeakerLayoutConstants.mainParticipantWidthRatio))
                    .trackingVisibility(of: activeParticipant)

                    GeometryReader { geometry in
                        let availableWidth = max(0, geometry.size.width)
                        let availableHeight = max(0, geometry.size.height)

                        // Prevent NaN calculations by ensuring positive values
                        if availableWidth > 0 && availableHeight > 0 {
                            let cellWidth = max(1, availableWidth - ActiveSpeakerLayoutConstants.spacing)
                            let cellHeight = max(1, cellWidth / ActiveSpeakerLayoutConstants.aspectRatio)

                            let rowsVisible = max(1, Int((availableHeight + ActiveSpeakerLayoutConstants.spacing) / (cellHeight + ActiveSpeakerLayoutConstants.spacing)))

                            let maxVisibleItems = rowsVisible

                            let takeCount =
                                maxVisibleItems >= restOfParticipants.count
                                ? restOfParticipants.count
                                : max(1, maxVisibleItems - 1)

                            let visibleItems = Array(restOfParticipants.prefix(takeCount))
                            let hiddenItems = Array(restOfParticipants.dropFirst(takeCount))

                            VStack(spacing: ActiveSpeakerLayoutConstants.spacing) {
                                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, participant in
                                    ParticipantVideoCard(
                                        participant: participant,
                                        activeSpeakerId: activeSpeakerId
                                    )
                                    .id("\(participant.id)_\(index)_\(visibleItems.count)")
                                    .aspectRatio(ActiveSpeakerLayoutConstants.aspectRatio, contentMode: .fit)
                                    .trackingVisibility(of: participant)
                                }

                                if !hiddenItems.isEmpty {
                                    HiddenParticipantsTile(
                                        participantNames: hiddenItems.map { $0.name }
                                    )
                                    .id("hidden_\(hiddenItems.count)_\(visibleItems.count)")
                                    .aspectRatio(ActiveSpeakerLayoutConstants.aspectRatio, contentMode: .fit)
                                    .onAppear {
                                        hiddenItems.forEach { $0.onDisappear?() }
                                    }
                                }
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                        } else {
                            EmptyView()
                        }
                    }
                    .frame(width: max(1, outerGeometry.size.width * ActiveSpeakerLayoutConstants.sidebarWidthRatio))
                }
            } else {
                EmptyView()
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

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
                        .onAppear {
                            hiddenParticipants.forEach { $0.onDisappear?() }
                        }
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
