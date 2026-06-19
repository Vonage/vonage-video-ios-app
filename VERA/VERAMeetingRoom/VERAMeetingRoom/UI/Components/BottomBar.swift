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
    public let overflowPresentation: BottomBarOverflowPresentation
    public let overflowSelectionBehavior: BottomBarOverflowSelectionBehavior
    public let action: () -> Void

    public init(
        id: String? = nil,
        label: String,
        accessibilityIdentifier: String? = nil,
        image: Image,
        isActive: Bool = false,
        accessory: BottomBarButtonAccessory? = nil,
        overflowPresentation: BottomBarOverflowPresentation = .gridItem,
        overflowSelectionBehavior: BottomBarOverflowSelectionBehavior = .performActionBeforeDismiss,
        action: @escaping () -> Void
    ) {
        self.id = id ?? label
        self.label = label
        self.accessibilityIdentifier = accessibilityIdentifier
        self.image = image
        self.isActive = isActive
        self.accessory = accessory
        self.overflowPresentation = overflowPresentation
        self.overflowSelectionBehavior = overflowSelectionBehavior
        self.action = action
    }

    @MainActor
    public init(
        _ presenter: any BottomItemPresentable,
        isActive: Bool? = nil,
        overflowSelectionBehavior: BottomBarOverflowSelectionBehavior? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            id: presenter.id,
            label: presenter.label,
            accessibilityIdentifier: presenter.accessibilityIdentifier,
            image: presenter.image,
            isActive: isActive ?? presenter.isActive,
            accessory: presenter.accessory,
            overflowPresentation: presenter.overflowPresentation,
            overflowSelectionBehavior: overflowSelectionBehavior ?? presenter.overflowSelectionBehavior,
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
    @Environment(\.meetingRoomTheme) private var theme

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
    @State private var isOverflowPresented = false
    @State private var pendingOverflowAction: (() -> Void)?

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
            let buttonGroups = extraButtonGroups(availableWidth: geometry.size.width)

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
                    buildExtraButtons(groups: buttonGroups)
                    EndCallControlButton(action: actions.onEndCall)
                }
                .padding(.horizontal, BottomBarConstants.containerPaddingHorizontal)
                .padding(.vertical, BottomBarConstants.containerPaddingVertical)
            }
            .background(BottomBarBackground())
            .padding(.bottom, BottomBarConstants.containerPaddingBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .sheet(isPresented: $isOverflowPresented, onDismiss: performPendingOverflowAction) {
                buildOverflowSheet(buttons: buttonGroups.overflow)
            }
            .onChange(of: buttonGroups.overflow.map(\.id)) { overflowButtonIds in
                if overflowButtonIds.isEmpty {
                    isOverflowPresented = false
                }
            }
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

    func extraButtonGroups(availableWidth: CGFloat) -> (inline: [BottomBarButton], overflow: [BottomBarButton]) {
        guard !extraButtons.isEmpty else {
            return (inline: [], overflow: [])
        }

        let maxExtraButtons = calculateMaxExtraButtons(availableWidth: availableWidth)
        guard maxExtraButtons < extraButtons.count else {
            return (inline: extraButtons, overflow: [])
        }

        let inlineButtonsCount = max(0, maxExtraButtons - 1)
        let inlineButtons = Array(extraButtons.prefix(inlineButtonsCount))
        let overflowButtons = Array(extraButtons.dropFirst(inlineButtonsCount))

        return (inline: inlineButtons, overflow: overflowButtons)
    }

    private func buildOverflowSheet(buttons: [BottomBarButton]) -> some View {
        BottomBarOverflowSheet(buttons: buttons, onSelect: handleOverflowButtonSelection)
            .presentationDetents([.medium, .large])
            .opaquePresentationBackground(theme.background)
    }

    private func handleOverflowButtonSelection(_ button: BottomBarButton) {
        switch button.overflowSelectionBehavior {
        case .performActionBeforeDismiss:
            button.action()
            isOverflowPresented = false
        case .dismissBeforeAction:
            pendingOverflowAction = button.action
            isOverflowPresented = false
        }
    }

    private func performPendingOverflowAction() {
        guard let action = pendingOverflowAction else { return }

        pendingOverflowAction = nil
        DispatchQueue.main.async {
            action()
        }
    }

    @ViewBuilder
    private func buildExtraButtons(groups: (inline: [BottomBarButton], overflow: [BottomBarButton])) -> some View {
        ForEach(groups.inline) { button in
            buildInlineButton(button)
        }

        if !groups.overflow.isEmpty {
            buildOverflowButton()
        }
    }

    private func buildOverflowButton() -> some View {
        BottomBarInlineButton(
            image: Image(systemName: "ellipsis.circle"),
            isActive: isOverflowPresented,
            accessibilityIdentifier: MeetingRoomAccessibilityID.moreOptionsButton
        ) {
            isOverflowPresented.toggle()
        }
        .accessibilityLabel("More options")
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
