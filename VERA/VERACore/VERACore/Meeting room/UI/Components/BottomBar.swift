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
    public let image: Image
    public let content: () -> AnyView
    public let onTap: () -> Void

    public init<Content: View>(
        label: String,
        image: Image,
        onTap: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = label
        self.label = label
        self.image = image
        self.onTap = onTap
        self.content = { AnyView(content()) }
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
                            action: actions.onToggleMic)
                    }
                    if allowCameraControl {
                        ControlImageButton(
                            isActive: isCameraEnabled,
                            image: isCameraEnabled
                                ? VERACommonUIAsset.Images.videoSolid.swiftUIImage
                                : VERACommonUIAsset.Images.videoOffSolid.swiftUIImage,
                            action: actions.onToggleCamera)
                    }
                    LayoutControlButton(layout: currentLayout, action: actions.onToggleLayout)
                    if showParticipantList {
                        ParticipantsBadgeButton(
                            participantsCount: participantsCount,
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

    private func calculateMaxExtraButtons(availableWidth: CGFloat) -> Int {
        let buttonWidth = BottomBarConstants.buttonWidth
        let spacing = BottomBarConstants.buttonSpacing
        let padding = BottomBarConstants.containerPaddingHorizontal * 2

        // Calculate base buttons count
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

        // Calculate space needed for base buttons
        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + padding * 2

        // Calculate remaining width for extra buttons
        let remainingWidth = availableWidth - baseButtonsWidth

        // How many extra buttons can fit?
        return max(0, Int((remainingWidth + spacing) / (buttonWidth + spacing)))
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
                    button.content()
                }
            } else {
                // Need to use menu
                Menu {
                    ForEach(extraButtons) { button in
                        Button(action: button.onTap) {
                            HStack {
                                button.image
                                    .tint(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                                Text(button.label)
                                    .tint(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                            }
                        }
                    }
                } label: {
                    ButtonImage(image: Image(systemName: "ellipsis.circle"))
                        .accessibilityLabel("More options")
                }
            }
        }
    }
}

struct BottomBarBackground: View {
    var body: some View {
        #if os(macOS)
            RoundedRectangle(cornerRadius: BottomBarConstants.cornerRadius)
                .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(0.8))
        #else
            Group {
                if #available(iOS 26.0, *) {
                    glassEffectBackground()
                } else {
                    RoundedRectangle(cornerRadius: BottomBarConstants.cornerRadius)
                        .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(0.8))
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
