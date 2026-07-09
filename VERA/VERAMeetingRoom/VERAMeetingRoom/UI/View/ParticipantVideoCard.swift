//
//  Created by Vonage on 23/7/25.
//

import AVKit
import SwiftUI
import VERACommonUI
import VERADomain

/// Constants for ParticipantVideoCard layout and appearance
enum ParticipantVideoCardConstants {
    /// Aspect ratio of the video container (16:9)
    static let containerAspectRatio: Double = 16.0 / 9.0

    /// Background opacity for card fills
    static let backgroundOpacity: Double = 0.8

    /// Padding around the avatar initials
    static let avatarPadding: CGFloat = 24

    /// Corner radius of the card
    static let cornerRadius: CGFloat = 8

    /// Stroke width for the active speaker border
    static let activeSpeakerStrokeWidth: CGFloat = 4

    /// Shadow radius of the card
    static let shadowRadius: CGFloat = 2

    /// Padding around the overlay content
    static let overlayPadding: CGFloat = 8

    /// Size of the pin and mic indicator circles
    static let indicatorSize: CGFloat = 28

    /// Inner padding of the pin and mic indicators
    static let indicatorPadding: CGFloat = 6

    /// Background opacity of the indicator circles
    static let indicatorBackgroundOpacity: Double = 0.6

    /// Size of the menu indicator circle
    static let menuIndicatorSize: CGFloat = 32

    /// Inner padding of the menu indicator
    static let menuIndicatorPadding: CGFloat = 6

    /// Size of the label icon inside the menu button
    static let labelIconSize: CGFloat = 16

    /// Horizontal padding of the name label
    static let nameLabelHorizontalPadding: CGFloat = 8

    /// Vertical padding of the name label
    static let nameLabelVerticalPadding: CGFloat = 4

    /// Corner radius of the name label background
    static let nameLabelCornerRadius: CGFloat = 8

    /// Background opacity of the name label
    static let nameLabelBackgroundOpacity: Double = 0.6
}

struct ParticipantVideoCard: View {
    @Environment(\.meetingRoomTheme) private var theme
    let participant: UIParticipant
    let activeSpeakerId: String?
    var shouldFlipHorizontally: Bool { participant.isRemote && !participant.isScreenshare }

    var body: some View {
        Group {
            if participant.isCameraEnabled {
                ZStack {
                    Rectangle()
                        .fill(
                            theme.vGray4.opacity(
                                ParticipantVideoCardConstants.backgroundOpacity
                            )
                        )
                        .if(
                            !participant.isScreenshare,
                            transform: { view in
                                view.aspectRatio(ParticipantVideoCardConstants.containerAspectRatio, contentMode: .fit)
                            }
                        )
                        .if(
                            participant.isScreenshare,
                            transform: { view in
                                view.aspectRatio(participant.aspectRatio, contentMode: .fit)
                            }
                        )
                        .overlay(
                            ZStack {
                                if participant.isScreenshare {
                                    participant.view
                                        .aspectRatio(participant.aspectRatio, contentMode: .fit)
                                        .clipped()

                                    ParticipantVideoCardOverlays(
                                        participantID: participant.id,
                                        isMicEnabled: participant.isMicEnabled,
                                        name: participant.name,
                                        isPinned: participant.isPinned,
                                        canTogglePinState: participant.canTogglePinState,
                                        isRemote: participant.isRemote,
                                        audioLevel: participant.audioLevel,
                                        isLocal: !participant.isRemote,
                                        onTogglePin: participant.onTogglePin,
                                        onForceMute: participant.onForceMute
                                    )
                                } else {
                                    participant.view
                                        .horizontallyFlipped(shouldFlipHorizontally)
                                        .aspectRatio(participant.aspectRatio, contentMode: .fit)
                                        .clipped()

                                    ParticipantVideoCardOverlays(
                                        participantID: participant.id,
                                        isMicEnabled: participant.isMicEnabled,
                                        name: participant.name,
                                        isPinned: participant.isPinned,
                                        canTogglePinState: participant.canTogglePinState,
                                        isRemote: participant.isRemote,
                                        audioLevel: participant.audioLevel,
                                        isLocal: !participant.isRemote,
                                        onTogglePin: participant.onTogglePin,
                                        onForceMute: participant.onForceMute
                                    )
                                }
                            }
                        )
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(
                            theme.vGray4.opacity(
                                ParticipantVideoCardConstants.backgroundOpacity
                            )
                        )
                        .if(
                            !participant.isScreenshare,
                            transform: { view in
                                view.aspectRatio(ParticipantVideoCardConstants.containerAspectRatio, contentMode: .fit)
                            }
                        )
                        .if(
                            participant.isScreenshare,
                            transform: { view in
                                view.aspectRatio(participant.aspectRatio, contentMode: .fit)
                            }
                        )
                        .overlay {
                            ZStack {
                                Rectangle()
                                    .fill(
                                        theme.vGray4.opacity(
                                            ParticipantVideoCardConstants.backgroundOpacity
                                        )
                                    )
                                    .overlay(
                                        AvatarInitials(state: .init(userName: participant.name))
                                            .padding(ParticipantVideoCardConstants.avatarPadding)
                                    )
                                    .aspectRatio(participant.aspectRatio, contentMode: .fit)
                                    .clipped()

                                ParticipantVideoCardOverlays(
                                    participantID: participant.id,
                                    isMicEnabled: participant.isMicEnabled,
                                    name: participant.name,
                                    isPinned: participant.isPinned,
                                    canTogglePinState: participant.canTogglePinState,
                                    isRemote: participant.isRemote,
                                    audioLevel: participant.audioLevel,
                                    isLocal: !participant.isRemote,
                                    onTogglePin: participant.onTogglePin,
                                    onForceMute: participant.onForceMute
                                )
                            }
                        }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: ParticipantVideoCardConstants.cornerRadius)
                .stroke(
                    theme.primary,
                    lineWidth: participant.id == activeSpeakerId
                        ? ParticipantVideoCardConstants.activeSpeakerStrokeWidth : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: ParticipantVideoCardConstants.cornerRadius))
        .shadow(radius: ParticipantVideoCardConstants.shadowRadius)
        .accessibilityAnchor(MeetingRoomAccessibilityID.participantCard(participant.id))
        .animation(.easeInOut(duration: 0.25), value: participant.aspectRatio)
    }
}

struct ParticipantVideoCardOverlays: View {

    let participantID: String
    let isMicEnabled: Bool
    let name: String
    let isPinned: Bool
    let canTogglePinState: Bool
    let isRemote: Bool
    let audioLevel: Float
    let isLocal: Bool
    var onTogglePin: (() -> Void)?
    var onForceMute: (() -> Void)?

    var body: some View {
        VStack {
            HStack {
                if isPinned {
                    VERACommonUIAsset.Images.pin2Solid.swiftUIImage
                        .foregroundColor(.white)
                        .padding(ParticipantVideoCardConstants.indicatorPadding)
                        .background(
                            Color.black.opacity(
                                ParticipantVideoCardConstants.indicatorBackgroundOpacity
                            )
                        )
                        .clipShape(Circle())
                        .frame(
                            width: ParticipantVideoCardConstants.indicatorSize,
                            height: ParticipantVideoCardConstants.indicatorSize)
                }
                Spacer()
                if isLocal {
                    ZStack {
                        AudioLevelIndicatorView(
                            audioLevel: audioLevel,
                            isMicEnabled: isMicEnabled)
                    }
                    .microphoneStateAccessibilityAnchor(
                        participantID: participantID,
                        isMicEnabled: isMicEnabled
                    )
                    .accessibilityElement(children: .contain)
                } else {
                    MicIndicator(
                        participantID: participantID,
                        isMicEnabled: isMicEnabled,
                        participantName: name,
                        onForceMute: onForceMute
                    )
                }
            }
            Spacer()
            HStack {
                NameLabel(name: name)
                Spacer()
                if let onTogglePin, canTogglePinState {
                    Menu {
                        Button {
                            onTogglePin()
                        } label: {
                            Label {
                                Text(isPinned ? String(localized: "Unpin") : String(localized: "Pin"))
                            } icon: {
                                (isPinned
                                    ? VERACommonUIAsset.Images.pin2OffSolid.swiftUIImage
                                    : VERACommonUIAsset.Images.pin2Solid.swiftUIImage)
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(
                                        width: ParticipantVideoCardConstants.labelIconSize,
                                        height: ParticipantVideoCardConstants.labelIconSize
                                    )
                                    .foregroundStyle(.white)
                            }
                        }
                    } label: {
                        MenuIndicator()
                    }
                }
            }
        }
        .padding(ParticipantVideoCardConstants.overlayPadding)
    }
}

struct NameLabel: View {
    @Environment(\.meetingRoomTheme) private var theme
    var name: String

    var body: some View {
        Text(name)
            .font(.caption)
            .foregroundColor(theme.onAccent)
            .padding(.horizontal, ParticipantVideoCardConstants.nameLabelHorizontalPadding)
            .padding(.vertical, ParticipantVideoCardConstants.nameLabelVerticalPadding)
            .background(
                theme.accent.opacity(ParticipantVideoCardConstants.nameLabelBackgroundOpacity),
                in: RoundedRectangle(
                    cornerRadius: ParticipantVideoCardConstants.nameLabelCornerRadius,
                    style: .continuous
                )
            )
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

struct MicIndicator: View {
    @Environment(\.meetingRoomTheme) private var theme
    var participantID: String
    var isMicEnabled: Bool
    var participantName: String
    var onForceMute: (() -> Void)?
    var forceMuteAccessibilityIdentifier: String?

    var isForceMuteEnabled: Bool {
        isMicEnabled && onForceMute != nil
    }

    var forceMuteAccessibilityLabel: String {
        String(localized: "Mute \(participantName)")
    }

    var body: some View {
        ZStack {
            if isForceMuteEnabled {
                Button {
                    onForceMute?()
                } label: {
                    indicator
                }
                .buttonStyle(.plain)
                .accessibilityLabel(forceMuteAccessibilityLabel)
                .accessibilityIdentifier(
                    forceMuteAccessibilityIdentifier
                        ?? MeetingRoomAccessibilityID.participantForceMuteButton(participantID)
                )
            } else {
                indicator
            }

        }
        .microphoneStateAccessibilityAnchor(
            participantID: participantID,
            isMicEnabled: isMicEnabled
        )
        .accessibilityElement(children: .contain)
    }

    private var indicator: some View {
        MicIndicatorImage(isMicEnabled: isMicEnabled)
            .foregroundColor(isMicEnabled ? .white : theme.error)
            .padding(ParticipantVideoCardConstants.indicatorPadding)
            .background(Color.black.opacity(ParticipantVideoCardConstants.indicatorBackgroundOpacity))
            .clipShape(Circle())
            .frame(
                width: ParticipantVideoCardConstants.indicatorSize,
                height: ParticipantVideoCardConstants.indicatorSize)
    }
}

extension View {
    fileprivate func microphoneStateAccessibilityAnchor(
        participantID: String,
        isMicEnabled: Bool
    ) -> some View {
        accessibilityAnchor(
            isMicEnabled
                ? MeetingRoomAccessibilityID.participantMicEnabled(participantID)
                : MeetingRoomAccessibilityID.participantMicDisabled(participantID),
            label: isMicEnabled ? "Microphone enabled" : "Microphone disabled",
            size: CGSize(
                width: ParticipantVideoCardConstants.indicatorSize,
                height: ParticipantVideoCardConstants.indicatorSize
            )
        )
    }
}

struct MenuIndicator: View {
    var body: some View {
        Circle()
            .fill(Color.black.opacity(ParticipantVideoCardConstants.indicatorBackgroundOpacity))
            .frame(
                width: ParticipantVideoCardConstants.menuIndicatorSize,
                height: ParticipantVideoCardConstants.menuIndicatorSize
            )
            .overlay {
                VERACommonUIAsset.Images.moreVerticalSolid.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .padding(ParticipantVideoCardConstants.menuIndicatorPadding)
            }
    }
}

struct MicIndicatorImage: View {
    var isMicEnabled: Bool

    var body: some View {
        if isMicEnabled {
            VERACommonUIAsset.Images.microphoneLine.swiftUIImage
        } else {
            VERACommonUIAsset.Images.micMuteLine.swiftUIImage
        }
    }
}

#Preview {
    ParticipantVideoCard(
        participant: UIParticipant(
            participant: Participant(
                id: "",
                name: "name",
                isMicEnabled: true,
                isCameraEnabled: true,
                videoDimensions: .zero,
                creationTime: Date(),
                isScreenshare: false,
                view: AnyView(EmptyView())),
            isPinned: false),
        activeSpeakerId: ""
    )
}

#Preview {
    ParticipantVideoCard(
        participant: UIParticipant(
            participant: Participant(
                id: "",
                name: "name",
                isMicEnabled: true,
                isCameraEnabled: true,
                videoDimensions: .zero,
                creationTime: Date(),
                isScreenshare: false,
                view: AnyView(EmptyView())),
            isPinned: true),
        activeSpeakerId: ""
    )
}

#Preview {
    ParticipantVideoCard(
        participant: UIParticipant(
            participant: Participant(
                id: "",
                name: "name",
                isMicEnabled: false,
                isCameraEnabled: false,
                videoDimensions: .zero,
                creationTime: Date(),
                isScreenshare: false,
                view: AnyView(EmptyView())),
            isPinned: false),
        activeSpeakerId: ""
    )
}
