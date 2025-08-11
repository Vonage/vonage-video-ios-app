//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

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
                .id(participants.first!.id + "_main")
                .frame(maxWidth: .infinity, minHeight: 200)
                .transition(.opacity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.4), value: participants.count)
        .animation(.easeInOut(duration: 0.3), value: horizontalSizeClass)
        .animation(.easeInOut(duration: 0.3), value: verticalSizeClass)
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
            HStack(spacing: 8) {
                ParticipantVideoCard(
                    participant: activeParticipant,
                    activeSpeakerId: activeSpeakerId
                )
                .id(activeParticipant.id + "_main")
                .frame(width: outerGeometry.size.width * 0.70)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let availableHeight = geometry.size.height

                    let cellWidth = availableWidth - spacing
                    let cellHeight = cellWidth / aspectRatio

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
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }

                        if !hiddenItems.isEmpty {
                            HiddenParticipantsTile(
                                participantNames: hiddenItems.map { $0.name }
                            )
                            .id("hidden_\(hiddenItems.count)_\(visibleItems.count)")
                            .aspectRatio(aspectRatio, contentMode: .fit)
                            .transition(.opacity)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: participants.map(\.id))
                }
                .frame(width: outerGeometry.size.width * 0.30)
                .transition(.move(edge: .trailing).combined(with: .opacity))
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
    let activeSpeakerId: String?

    public var body: some View {
        VStack(spacing: 8) {
            ParticipantVideoCard(
                participant: activeParticipant,
                activeSpeakerId: activeSpeakerId
            )
            .transition(
                .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))

            Group {
                if restOfParticipants.count == 1 {
                    ParticipantVideoCard(
                        participant: restOfParticipants[0],
                        activeSpeakerId: activeSpeakerId
                    )
                    .id(restOfParticipants[0].id + "_other")
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                } else if restOfParticipants.count == 2 {
                    HStack {
                        ParticipantVideoCard(
                            participant: restOfParticipants[0],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[0].id + "_other")
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        ParticipantVideoCard(
                            participant: restOfParticipants[1],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[1].id + "_other")
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                    .transition(.slide)
                } else if restOfParticipants.count >= 3 {
                    HStack {
                        ParticipantVideoCard(
                            participant: restOfParticipants[0],
                            activeSpeakerId: activeSpeakerId
                        )
                        .id(restOfParticipants[0].id + "_other")
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        HiddenParticipantsTile(
                            participantNames: Array(restOfParticipants.dropFirst()).map { $0.name }
                        )
                        .id("hidden_participants")
                        .transition(.opacity)
                    }
                    .transition(.slide)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: restOfParticipants.count)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.4), value: participants.map(\.id))
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
