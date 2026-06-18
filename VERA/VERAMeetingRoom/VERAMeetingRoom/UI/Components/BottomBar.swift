//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

public enum BottomBarConstants {
    public static let buttonHeight: CGFloat = 50
    public static let buttonSpacing: CGFloat = 8
    public static let containerPaddingHorizontal: CGFloat = 8
    public static let containerPaddingVertical: CGFloat = 6
    public static let containerPaddingBottom: CGFloat = 2
    public static let cornerRadius: CGFloat = 16

    /// Height of the visible bottom bar (button + internal vertical padding)
    public static var contentHeight: CGFloat {
        buttonHeight + (containerPaddingVertical * 2)
    }

    /// Total height including external bottom padding
    public static var totalHeight: CGFloat {
        contentHeight + containerPaddingBottom
    }

    // Internal alias for backward compatibility
    static var buttonWidth: CGFloat { buttonHeight }
}

public struct BottomBarButton: Identifiable {
    public let id: String
    public let label: String
    public let accessibilityIdentifier: String?
    public let image: Image
    public let isActive: Bool
    public let accessory: BottomBarButtonAccessory?
    public let action: () -> Void

    public init(
        id: String? = nil,
        label: String,
        accessibilityIdentifier: String? = nil,
        image: Image,
        isActive: Bool = false,
        accessory: BottomBarButtonAccessory? = nil,
        action: @escaping () -> Void
    ) {
        self.id = id ?? label
        self.label = label
        self.accessibilityIdentifier = accessibilityIdentifier
        self.image = image
        self.isActive = isActive
        self.accessory = accessory
        self.action = action
    }

    @MainActor
    public init(
        _ presenter: any BottomItemPresentable,
        isActive: Bool? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            id: presenter.id,
            label: presenter.label,
            accessibilityIdentifier: presenter.accessibilityIdentifier,
            image: presenter.image,
            isActive: isActive ?? presenter.isActive,
            accessory: presenter.accessory,
            action: action ?? presenter.performAction
        )
    }
}

public struct MeetingRoomActions {
    let onShare: (String) -> Void
    let onRetry: () -> Void
    let onToggleMic: () -> Void
    let onToggleCamera: () -> Void
    let onCameraSwitch: () -> Void
    let onEndCall: () -> Void
    let onToggleParticipants: () -> Void
    let onToggleLayout: () -> Void

    init(
        onShare: @escaping (String) -> Void = { _ in },
        onRetry: @escaping () -> Void = {},
        onToggleMic: @escaping () -> Void = {},
        onToggleCamera: @escaping () -> Void = {},
        onCameraSwitch: @escaping () -> Void = {},
        onEndCall: @escaping () -> Void = {},
        onToggleParticipants: @escaping () -> Void = {},
        onToggleLayout: @escaping () -> Void = {},
    ) {
        self.onShare = onShare
        self.onRetry = onRetry
        self.onToggleMic = onToggleMic
        self.onToggleCamera = onToggleCamera
        self.onCameraSwitch = onCameraSwitch
        self.onEndCall = onEndCall
        self.onToggleParticipants = onToggleParticipants
        self.onToggleLayout = onToggleLayout
    }
}

struct BottomBar: View {
    private let isMicEnabled: Bool
    private let isCameraEnabled: Bool
    private let isParticipantsListPresented: Bool
    private let participantsCount: Int
    private let allowMicrophoneControl: Bool
    private let allowCameraControl: Bool
    private let showParticipantList: Bool
    private let currentLayout: MeetingRoomLayout
    private let actions: MeetingRoomActions
    @Binding private var extraButtons: [BottomBarButton]

    init(
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        isParticipantsListPresented: Bool = false,
        participantsCount: Int,
        allowMicrophoneControl: Bool,
        allowCameraControl: Bool,
        showParticipantList: Bool,
        currentLayout: MeetingRoomLayout,
        actions: MeetingRoomActions,
        extraButtons: Binding<[BottomBarButton]> = .constant([])
    ) {
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.isParticipantsListPresented = isParticipantsListPresented
        self.participantsCount = participantsCount
        self.currentLayout = currentLayout
        self.allowMicrophoneControl = allowMicrophoneControl
        self.allowCameraControl = allowCameraControl
        self.showParticipantList = showParticipantList
        self.actions = actions
        self._extraButtons = extraButtons
    }

    var body: some View {
        GeometryReader { geometry in
            HStack {
                HStack(alignment: .center) {
                    if allowMicrophoneControl {
                        ControlImageButton(
                            isActive: isMicEnabled,
                            image: isMicEnabled
                                ? VERACommonUIAsset.Images.microphone2Solid.swiftUIImage
                                : VERACommonUIAsset.Images.micMuteSolid.swiftUIImage,
                            action: actions.onToggleMic
                        )
                        .accessibilityIdentifier(
                            isMicEnabled
                                ? MeetingRoomAccessibilityID.micEnabled
                                : MeetingRoomAccessibilityID.micDisabled)
                    }
                    if allowCameraControl {
                        ControlImageButton(
                            isActive: isCameraEnabled,
                            image: isCameraEnabled
                                ? VERACommonUIAsset.Images.videoSolid.swiftUIImage
                                : VERACommonUIAsset.Images.videoOffSolid.swiftUIImage,
                            action: actions.onToggleCamera
                        )
                        .accessibilityIdentifier(
                            isCameraEnabled
                                ? MeetingRoomAccessibilityID.cameraEnabled
                                : MeetingRoomAccessibilityID.cameraDisabled)
                    }
                    LayoutControlButton(layout: currentLayout, action: actions.onToggleLayout)
                    if showParticipantList {
                        ParticipantsBadgeButton(
                            participantsCount: participantsCount,
                            isActive: isParticipantsListPresented,
                            onToggleParticipants: actions.onToggleParticipants)
                    }
                    buildExtraButtons(availableWidth: geometry.size.width)
                    EndCallControlButton(action: actions.onEndCall)
                }
                .padding(.horizontal, BottomBarConstants.containerPaddingHorizontal)
                .padding(.vertical, BottomBarConstants.containerPaddingVertical)
            }
            .background(BottomBarBackground())
            .padding(.bottom, BottomBarConstants.containerPaddingBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    func calculateMaxExtraButtons(availableWidth: CGFloat) -> Int {
        let buttonWidth = BottomBarConstants.buttonWidth
        let spacing = BottomBarConstants.buttonSpacing
        let horizontalPadding = BottomBarConstants.containerPaddingHorizontal * 2

        var baseButtonsCount = 1  // EndCallControlButton always present
        if allowMicrophoneControl {
            baseButtonsCount += 1
        }
        if allowCameraControl {
            baseButtonsCount += 1
        }
        baseButtonsCount += 1  // LayoutControlButton always present
        if showParticipantList {
            baseButtonsCount += 1
        }

        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + horizontalPadding

        let remainingWidth = availableWidth - baseButtonsWidth

        return max(0, Int(remainingWidth / (buttonWidth + spacing)))
    }

    @ViewBuilder
    private func buildExtraButtons(availableWidth: CGFloat) -> some View {
        if extraButtons.isEmpty {
            EmptyView()
        } else {
            let maxExtraButtons = calculateMaxExtraButtons(availableWidth: availableWidth)

            if maxExtraButtons >= extraButtons.count {
                // All buttons fit
                ForEach(extraButtons) { button in
                    buildInlineButton(button)
                }
            } else {
                let inlineButtonsCount = max(0, maxExtraButtons - 1)
                let inlineButtons = Array(extraButtons.prefix(inlineButtonsCount))
                let overflowButtons = Array(extraButtons.dropFirst(inlineButtonsCount))

                ForEach(inlineButtons) { button in
                    buildInlineButton(button)
                }

                buildOverflowMenu(buttons: overflowButtons)
            }
        }
    }

    private func buildOverflowMenu(buttons: [BottomBarButton]) -> some View {
        Menu {
            ForEach(buttons) { button in
                BottomBarMenuItem(
                    image: button.image,
                    label: button.label,
                    accessibilityIdentifier: button.accessibilityIdentifier ?? button.id,
                    action: button.action
                )
            }
        } label: {
            ButtonImage(image: Image(systemName: "ellipsis.circle"))
                .accessibilityLabel("More options")
        }
        .accessibilityIdentifier(MeetingRoomAccessibilityID.moreOptionsButton)
    }

    @ViewBuilder
    private func buildInlineButton(_ button: BottomBarButton) -> some View {
        BottomBarInlineButton(
            image: button.image,
            isActive: button.isActive,
            accessibilityIdentifier: button.accessibilityIdentifier ?? button.id,
            accessory: button.accessory,
            action: button.action
        )
    }
}

struct BottomBarBackground: View {
    @Environment(\.meetingRoomTheme) private var theme

    var body: some View {
        #if os(macOS)
            RoundedRectangle(cornerRadius: BottomBarConstants.cornerRadius)
                .fill(theme.vGray4.opacity(0.8))
        #else
            Group {
                if #available(iOS 26.0, *) {
                    glassEffectBackground()
                } else {
                    RoundedRectangle(cornerRadius: BottomBarConstants.cornerRadius)
                        .fill(theme.vGray4.opacity(0.8))
                }
            }
        #endif
    }

    #if !os(macOS)
        @available(iOS 26.0, *)
        private func glassEffectBackground() -> some View {
            RoundedRectangle(cornerRadius: BottomBarConstants.cornerRadius)
                .glassEffect(in: .rect(cornerRadius: BottomBarConstants.cornerRadius))
        }
    #endif
}

#Preview {
    VStack {
        BottomBar(
            isMicEnabled: false,
            isCameraEnabled: true,
            participantsCount: 25,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            showParticipantList: true,
            currentLayout: .activeSpeaker,
            actions: .init())
    }
    .background(Color.black)
}

#Preview {
    VStack {
        BottomBar(
            isMicEnabled: false,
            isCameraEnabled: true,
            participantsCount: 25,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            showParticipantList: true,
            currentLayout: .activeSpeaker,
            actions: .init())
    }
    .background(Color.white)
    .preferredColorScheme(.dark)
}
