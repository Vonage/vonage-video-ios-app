//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Shared layout constants used by the meeting room bottom bar.
public enum BottomBarConstants {
    /// The fixed height used for each bottom bar button.
    public static let buttonHeight: CGFloat = 50

    /// The horizontal spacing between adjacent bottom bar buttons.
    public static let buttonSpacing: CGFloat = 8

    /// The horizontal padding inside the bottom bar container.
    public static let containerPaddingHorizontal: CGFloat = 8

    /// The vertical padding inside the bottom bar container.
    public static let containerPaddingVertical: CGFloat = 6

    /// The external bottom padding below the bottom bar content.
    public static let containerPaddingBottom: CGFloat = 2

    /// The corner radius used by the bottom bar container background.
    public static let cornerRadius: CGFloat = 16

    /// Height of the visible bottom bar, including button height and internal vertical padding.
    public static var contentHeight: CGFloat {
        buttonHeight + (containerPaddingVertical * 2)
    }

    /// Total height reserved for the bottom bar, including external bottom padding.
    public static var totalHeight: CGFloat {
        contentHeight + containerPaddingBottom
    }

    // Internal alias for backward compatibility
    static var buttonWidth: CGFloat { buttonHeight }
}

/// A host-provided button that can be appended to the SDK bottom bar.
public struct BottomBarButton: Identifiable {
    /// Stable identifier used by SwiftUI and overflow handling.
    public let id: String

    /// User-facing label shown in overflow UI and accessibility contexts.
    public let label: String

    /// Optional accessibility identifier applied to the rendered button.
    public let accessibilityIdentifier: String?

    /// Icon rendered for the button.
    public let image: Image

    /// Whether the button should be rendered as active.
    public let isActive: Bool

    /// Optional accessory rendered with the button, such as a badge.
    public let accessory: BottomBarButtonAccessory?

    /// Preferred representation when the button is moved into overflow.
    public let overflowPresentation: BottomBarOverflowPresentation

    /// Defines whether overflow UI is dismissed before or after the action runs.
    public let overflowSelectionBehavior: BottomBarOverflowSelectionBehavior

    /// Optional request for SDK-managed presentation after `action` runs.
    ///
    /// Return a request when the button should ask the meeting room to present a
    /// dialog, overlay, or sheet. Return `nil` to keep presentation fully owned by
    /// the button action.
    public let presentationRequest: (@MainActor () -> MeetingRoomPresentationRequest?)?

    /// Action executed when the user taps the button.
    public let action: () -> Void

    /// Creates a bottom bar button from explicit values.
    ///
    /// - Parameters:
    ///   - id: Stable identifier. Defaults to `label` when omitted.
    ///   - label: User-facing button label.
    ///   - accessibilityIdentifier: Optional identifier for UI automation.
    ///   - image: Icon rendered for the button.
    ///   - isActive: Whether the button should be rendered as active.
    ///   - accessory: Optional accessory rendered with the button.
    ///   - overflowPresentation: Preferred overflow representation.
    ///   - overflowSelectionBehavior: Overflow dismissal behavior.
    ///   - presentationRequest: Optional SDK-managed presentation request.
    ///   - action: Action executed when the button is tapped.
    public init(
        id: String? = nil,
        label: String,
        accessibilityIdentifier: String? = nil,
        image: Image,
        isActive: Bool = false,
        accessory: BottomBarButtonAccessory? = nil,
        overflowPresentation: BottomBarOverflowPresentation = .gridItem,
        overflowSelectionBehavior: BottomBarOverflowSelectionBehavior = .performActionBeforeDismiss,
        presentationRequest: (@MainActor () -> MeetingRoomPresentationRequest?)? = nil,
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
        self.presentationRequest = presentationRequest
        self.action = action
    }

    /// Creates a bottom bar button by adapting a `BottomItemPresentable`.
    ///
    /// - Parameters:
    ///   - presenter: Presenter that supplies shared button display values.
    ///   - isActive: Optional active-state override.
    ///   - overflowSelectionBehavior: Optional overflow behavior override.
    ///   - presentationRequest: Optional SDK-managed presentation request.
    ///   - action: Optional action override. Defaults to `presenter.performAction`.
    @MainActor
    public init(
        _ presenter: any BottomItemPresentable,
        isActive: Bool? = nil,
        overflowSelectionBehavior: BottomBarOverflowSelectionBehavior? = nil,
        presentationRequest: (@MainActor () -> MeetingRoomPresentationRequest?)? = nil,
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
            presentationRequest: presentationRequest,
            action: action ?? presenter.performAction
        )
    }
}

/// Actions exposed by the meeting room for custom UI surfaces.
public struct MeetingRoomActions {
    /// Shares the current meeting URL or room identifier.
    public let onShare: (String) -> Void

    /// Retries the current meeting room connection flow.
    public let onRetry: () -> Void

    /// Toggles the local microphone state.
    public let onToggleMic: () -> Void

    /// Toggles the local camera state.
    public let onToggleCamera: () -> Void

    /// Switches between available local cameras.
    public let onCameraSwitch: () -> Void

    /// Ends the current call.
    public let onEndCall: () -> Void

    /// Toggles the SDK participant list presentation.
    public let onToggleParticipants: () -> Void

    /// Toggles the SDK meeting layout.
    public let onToggleLayout: () -> Void

    /// Creates a collection of meeting room actions.
    ///
    /// Parameters default to no-op closures so tests and previews can provide
    /// only the actions they need.
    public init(
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
    private let presentationHandler: MeetingRoomPresentationHandler
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
        presentationHandler: MeetingRoomPresentationHandler = .init(),
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
        self.presentationHandler = presentationHandler
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
            .presentationDragIndicator(.hidden)
            .opaquePresentationBackground(theme.background)
    }

    private func handleOverflowButtonSelection(_ button: BottomBarButton) {
        switch button.overflowSelectionBehavior {
        case .performActionBeforeDismiss:
            performExtraButton(button)
            isOverflowPresented = false
        case .dismissBeforeAction:
            pendingOverflowAction = {
                performExtraButton(button)
            }
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

    @MainActor
    func performExtraButton(_ button: BottomBarButton) {
        button.action()

        if let request = button.presentationRequest?() {
            presentationHandler.present(request)
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
            action: {
                performExtraButton(button)
            }
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
