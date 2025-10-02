//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

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

    let itemHeight: Double = 225
    let minItemWidth: Double = 300
    let spacing: Double = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if participants.count == 1 {
                ParticipantVideoCard(
                    participant: participants.first!,
                    activeSpeakerId: activeSpeakerId
                )
                .id(participants.first!.id + "_main_active")
                .frame(maxWidth: .infinity, minHeight: 200)
                .onAppear {
                    participants.first?.onAppear?()
                }
            } else if participants.count > 1 {
                Group {
                    if verticalSizeClass == .compact {
                        HorizontalActiveSpeakerLayoutView(
                            participants: participants,
                            activeSpeakerId: activeSpeakerId)
                    } else if horizontalSizeClass == .compact {
                        VerticalActiveSpeakerLayoutView(
                            participants: participants,
                            activeSpeakerId: activeSpeakerId)
                    } else {
                        HorizontalActiveSpeakerLayoutView(
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
    let activeSpeakerId: String?

    public var body: some View {
        GeometryReader { outerGeometry in
            if outerGeometry.size.width > 0 && outerGeometry.size.height > 0 {
                HStack(spacing: 8) {
                    ParticipantVideoCard(
                        participant: activeParticipant,
                        activeSpeakerId: activeSpeakerId
                    )
                    .id(activeParticipant.id + "_main")
                    .frame(width: max(1, outerGeometry.size.width * 0.70))

                    GeometryReader { geometry in
                        let availableWidth = max(0, geometry.size.width)
                        let availableHeight = max(0, geometry.size.height)

                        // Prevent NaN calculations by ensuring positive values
                        if availableWidth > 0 && availableHeight > 0 {
                            let cellWidth = max(1, availableWidth - spacing)
                            let cellHeight = max(1, cellWidth / aspectRatio)

                            let rowsVisible = max(1, Int((availableHeight + spacing) / (cellHeight + spacing)))

                            let maxVisibleItems = rowsVisible

                            let takeCount =
                                maxVisibleItems >= restOfParticipants.count
                                ? restOfParticipants.count
                                : max(1, maxVisibleItems - 1)

                            let visibleItems = Array(restOfParticipants.prefix(takeCount))
                            let hiddenItems = Array(restOfParticipants.dropFirst(takeCount))

                            VStack(spacing: spacing) {
                                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, participant in
                                    ParticipantVideoCard(
                                        participant: participant,
                                        activeSpeakerId: activeSpeakerId
                                    )
                                    .id("\(participant.id)_\(index)_\(visibleItems.count)")
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                }

                                if !hiddenItems.isEmpty {
                                    HiddenParticipantsTile(
                                        participantNames: hiddenItems.map { $0.name }
                                    )
                                    .id("hidden_\(hiddenItems.count)_\(visibleItems.count)")
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                }
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                            .onAppear {
                                hiddenItems.forEach { $0.onDisappear?() }
                                activeParticipant.onAppear?()
                                visibleItems.forEach { $0.onAppear?() }
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    .frame(width: max(1, outerGeometry.size.width * 0.30))
                }
            } else {
                EmptyView()
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let activeSpeakerId: String?

    public var body: some View {
        VStack(spacing: 8) {
            ParticipantVideoCard(
                participant: activeParticipant,
                activeSpeakerId: activeSpeakerId
            )
            .id(activeParticipant.id + "_main")

            Group {
                if restOfParticipants.count == 1 {
                    ParticipantVideoCard(
                        participant: restOfParticipants[0],
                        activeSpeakerId: activeSpeakerId
                    )
                    .id(restOfParticipants[0].id + "_other")
                    .onAppear {
                        activeParticipant.onAppear?()
                        restOfParticipants[0].onAppear?()
                    }
                } else if restOfParticipants.count == 2 {
                    HStack {
                        ParticipantVideoCard(
                            participant: restOfParticipants[0],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[0].id + "_other")

                        ParticipantVideoCard(
                            participant: restOfParticipants[1],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[1].id + "_other")
                        .onAppear {
                            activeParticipant.onAppear?()
                            restOfParticipants[0].onAppear?()
                            restOfParticipants[1].onAppear?()
                        }
                    }
                    .transition(.slide)
                } else if restOfParticipants.count >= 3 {
                    HStack {
                        ParticipantVideoCard(
                            participant: restOfParticipants[0],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[0].id + "_other")

                        let hiddenParticipants = Array(restOfParticipants.dropFirst())
                        HiddenParticipantsTile(
                            participantNames: hiddenParticipants.map { $0.name }
                        )
                        .id("hidden_participants")
                        .transition(.opacity)
                        .onAppear {
                            hiddenParticipants.forEach { $0.onDisappear?() }
                            activeParticipant.onAppear?()
                            restOfParticipants[0].onAppear?()
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
