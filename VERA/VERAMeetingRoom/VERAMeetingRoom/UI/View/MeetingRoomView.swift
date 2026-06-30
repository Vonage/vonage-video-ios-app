//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Layout constants for the meeting room screen.
private enum MeetingRoomViewConstants {
    /// Spring animation response for content transitions.
    static let springResponse: Double = 0.6
    /// Spring animation damping fraction.
    static let springDamping: Double = 0.8
    /// Spacing between status indicator icons.
    static let statusIconSpacing: CGFloat = 8
    /// Leading padding for the status indicator row.
    static let statusLeadingPadding: CGFloat = 16
    /// Top padding for the status indicator row.
    static let statusTopPadding: CGFloat = 16
    /// Size of the recording indicator icon.
    static let recordingIconSize: CGFloat = 20
    /// Pulse fraction for the recording indicator animation.
    static let recordingPulseFraction: CGFloat = 1.1
    /// Duration of the recording pulse animation in seconds.
    static let recordingPulseDuration: Double = 0.6
    /// Duration of the bottom bar fade animation.
    static let barFadeDuration: Double = 0.3
    /// Duration of the bar toggle animation.
    static let barToggleDuration: Double = 0.4
}

public struct ViewGenerator: Identifiable {
    public let id: String
    public let content: () -> AnyView

    public init<Content: View>(
        id: String = UUID().uuidString,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.content = { AnyView(content()) }
    }
}

public struct MeetingRoomView: View {
    @Environment(\.meetingRoomTheme) private var theme

    private let state: MeetingRoomState
    private let actions: MeetingRoomActions
    private let bottomBarContent: @MainActor (MeetingRoomBottomBarContext) -> AnyView?
    @Binding private var extraButtons: [BottomBarButton]
    @Binding private var extraTopTrailingButtons: [ViewGenerator]

    @State private var isBottomBarVisible = true
    @State private var isNavigationBarVisible = true
    @State private var showParticipantsList = false
    @State private var urlToShare: URL?
    @State private var activeDialogRequest: MeetingRoomPresentationRequest?
    @State private var activeOverlayRequest: MeetingRoomPresentationRequest?
    @State private var activeSheetRequest: MeetingRoomPresentationRequest?
    @State private var lastPresentedSheetRequest: MeetingRoomPresentationRequest?

    public init(
        state: MeetingRoomState,
        actions: MeetingRoomActions,
        bottomBarContent: @escaping @MainActor (MeetingRoomBottomBarContext) -> AnyView? = { _ in nil },
        extraButtons: Binding<[BottomBarButton]> = .constant([]),
        extraTopTrailingButtons: Binding<[ViewGenerator]> = .constant([])
    ) {
        self.state = state
        self.actions = actions
        self.bottomBarContent = bottomBarContent
        self._extraButtons = extraButtons
        self._extraTopTrailingButtons = extraTopTrailingButtons
    }

    public var body: some View {
        NavigationView {
            ScreenIdentifierContainer(MeetingRoomAccessibilityID.screen) {
                MeetingRoomContent(
                    participants: state.participants,
                    layout: state.layout,
                    activeSpeakerId: state.activeSpeakerId
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(
                    .spring(
                        response: MeetingRoomViewConstants.springResponse,
                        dampingFraction: MeetingRoomViewConstants.springDamping
                    ), value: isNavigationBarVisible
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleBarsVisibility()
                }

                VStack(alignment: .center) {
                    Spacer()
                    bottomBar
                        .opacity(isBottomBarVisible ? 1.0 : 0.0)
                        .animation(
                            .easeInOut(duration: MeetingRoomViewConstants.barFadeDuration), value: isBottomBarVisible
                        )
                        .onTapGesture {
                            showBars()
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: MeetingRoomViewConstants.statusIconSpacing) {
                        if state.archivingState.isArchiving {
                            recordingIndicator
                        }
                        if state.noiseSuppressionState.isEnabled {
                            noiseSuppressionIndicator
                        }
                        Spacer()
                    }
                    .padding(.leading, MeetingRoomViewConstants.statusLeadingPadding)
                    .padding(.top, MeetingRoomViewConstants.statusTopPadding)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .navigationTitle(state.roomName)
            .sheet(isPresented: $showParticipantsList) {
                ParticipantsListView(
                    participants: state.participants.sortedByName(),
                    participantsCount: state.participantsCount,
                    roomName: state.roomName,
                    meetingURL: state.roomURL
                ) {
                    showParticipantsList = false
                }
            }
            .sheet(
                item: $activeSheetRequest,
                onDismiss: {
                    lastPresentedSheetRequest?.onDismiss?()
                    lastPresentedSheetRequest = nil
                    activeSheetRequest = nil
                },
                content: { request in
                    presentationContent(for: request)
                }
            )
            .alert(item: $activeDialogRequest) { request in
                Alert(
                    title: Text(request.title),
                    message: request.message.map { Text($0) },
                    dismissButton: .default(Text("OK")) {
                        request.onDismiss?()
                        activeDialogRequest = nil
                    }
                )
            }
            .dismissibleOverlay(
                isPresented: activeOverlayRequestBinding,
                alignment: .bottom,
                edgePadding: BottomBarConstants.totalHeight + 4
            ) {
                if let request = activeOverlayRequest {
                    presentationContent(for: request)
                }
            }
            #if !os(macOS)
                .toolbar(isNavigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .if(iOS26Available()) { view in
                    view
                    .modifier(IOS26ToolbarModifier())
                }
                .if(
                    !iOS26Available()
                ) { view in
                    view
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.black, for: .navigationBar)

                }
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        toolbarContent
                    }
                }
                .tint(.white)
            #endif
        }
        #if !os(macOS)
            .navigationViewStyle(.stack)
        #endif
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct IOS26ToolbarModifier: ViewModifier {
        func body(content: Content) -> some View {
            #if os(macOS)
                content
            #else
                if #available(iOS 18.0, *) {
                    if #available(iOS 26.0, *) {
                        content
                            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
                    } else {
                        content
                            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
                    }
                } else {
                    content
                }
            #endif
        }
    }

    // MARK: - Auto-hide Controls Functions

    @ViewBuilder
    private var toolbarContent: some View {
        if !isIosAppOnMac && state.allowCameraControl {
            cameraSwitchButton
        }

        ForEach(extraTopTrailingButtons) { button in
            button.content()
        }

        if let roomURL = state.roomURL {
            shareButton(url: roomURL)
        }
    }

    private var recordingIndicator: some View {
        VStack(spacing: 0) {
            Image(systemName: "record.circle")
                .resizable()
                .frame(
                    width: MeetingRoomViewConstants.recordingIconSize,
                    height: MeetingRoomViewConstants.recordingIconSize
                )
                .foregroundStyle(theme.error)
                .pulsating(
                    pulseFraction: MeetingRoomViewConstants.recordingPulseFraction,
                    durationSeconds: MeetingRoomViewConstants.recordingPulseDuration
                )
        }
        .accessibilityIdentifier(MeetingRoomAccessibilityID.recordingIndicator)
    }

    private var noiseSuppressionIndicator: some View {
        VERACommonUIAsset.Images.noiseSuppressionEnabled.swiftUIImage
            .foregroundStyle(
                theme.onAccent)
    }

    private var cameraSwitchButton: some View {
        Button {
            onBottomBarInteraction()
            actions.onCameraSwitch()
        } label: {
            VERACommonUIAsset.Images.cameraSwitchLine.swiftUIImage
        }
        .disabled(!state.isCameraEnabled)
    }

    private func shareButton(url: URL) -> some View {
        ShareLink(item: url) {
            VERACommonUIAsset.Images.shareLine.swiftUIImage
        }
    }

    private var isIosAppOnMac: Bool {
        ProcessInfo.processInfo.isiOSAppOnMac
    }

    private func toggleBarsVisibility() {
        showBars(value: !isBottomBarVisible)
    }

    private func showBars(value: Bool = true) {
        withAnimation(.easeInOut(duration: MeetingRoomViewConstants.barToggleDuration)) {
            isBottomBarVisible = value
            isNavigationBarVisible = value
        }
    }

    private func onBottomBarInteraction() {
        showBars()
    }

    private var presentationHandler: MeetingRoomPresentationHandler {
        MeetingRoomPresentationHandler(
            present: { request in
                present(request)
            },
            dismiss: { id in
                dismissPresentation(id: id)
            }
        )
    }

    private var activeOverlayRequestBinding: Binding<Bool> {
        Binding(
            get: { activeOverlayRequest != nil },
            set: { isPresented in
                guard !isPresented else { return }
                activeOverlayRequest?.onDismiss?()
                activeOverlayRequest = nil
            }
        )
    }

    @MainActor
    private func present(_ request: MeetingRoomPresentationRequest) {
        switch request.style {
        case .dialog:
            activeDialogRequest = request
        case .overlay:
            activeOverlayRequest = request
        case .sheet:
            lastPresentedSheetRequest = request
            activeSheetRequest = request
        }
    }

    @MainActor
    private func dismissPresentation(id: String) {
        if activeDialogRequest?.id == id {
            activeDialogRequest?.onDismiss?()
            activeDialogRequest = nil
        }
        if activeOverlayRequest?.id == id {
            activeOverlayRequest?.onDismiss?()
            activeOverlayRequest = nil
        }
        if activeSheetRequest?.id == id {
            activeSheetRequest?.onDismiss?()
            activeSheetRequest = nil
            lastPresentedSheetRequest = nil
        }
    }

    @ViewBuilder
    private func presentationContent(for request: MeetingRoomPresentationRequest) -> some View {
        if let content = request.content {
            content
        } else {
            VStack(spacing: 12) {
                Text(request.title)
                    .font(.headline)
                if let message = request.message {
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                Button("Dismiss") {
                    dismissPresentation(id: request.id)
                }
            }
            .padding(24)
            .background(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if let customBottomBarContent = bottomBarContent(
            MeetingRoomBottomBarContext(
                state: state,
                actions: wrappedActions,
                buttons: extraButtons,
                controls: bottomBarControls,
                presentationHandler: presentationHandler
            )
        ) {
            customBottomBarContent
        } else {
            BottomBar(
                isMicEnabled: state.isMicEnabled,
                isCameraEnabled: state.isCameraEnabled,
                isParticipantsListPresented: showParticipantsList,
                participantsCount: state.participantsCount,
                allowMicrophoneControl: state.allowMicrophoneControl,
                allowCameraControl: state.allowCameraControl,
                showParticipantList: state.showParticipantList,
                currentLayout: state.layout,
                actions: wrappedActions,
                presentationHandler: presentationHandler,
                extraButtons: _extraButtons
            )
        }
    }

    var bottomBarControls: MeetingRoomBottomBarControls {
        MeetingRoomBottomBarControls(
            microphone: microphoneControl,
            camera: cameraControl,
            participants: participantsControl,
            layout: layoutControl,
            endCall: endCallControl
        )
    }

    var microphoneControl: MeetingRoomBottomBarControl {
        MeetingRoomBottomBarControl(
            id: "microphone",
            label: "Microphone",
            image: state.isMicEnabled
                ? VERACommonUIAsset.Images.microphone2Solid.swiftUIImage
                : VERACommonUIAsset.Images.micMuteSolid.swiftUIImage,
            isActive: state.isMicEnabled,
            accessibilityIdentifier: state.isMicEnabled
                ? MeetingRoomAccessibilityID.micEnabled
                : MeetingRoomAccessibilityID.micDisabled,
            action: wrappedActions.onToggleMic
        )
    }

    var cameraControl: MeetingRoomBottomBarControl {
        MeetingRoomBottomBarControl(
            id: "camera",
            label: "Camera",
            image: state.isCameraEnabled
                ? VERACommonUIAsset.Images.videoSolid.swiftUIImage
                : VERACommonUIAsset.Images.videoOffSolid.swiftUIImage,
            isActive: state.isCameraEnabled,
            accessibilityIdentifier: state.isCameraEnabled
                ? MeetingRoomAccessibilityID.cameraEnabled
                : MeetingRoomAccessibilityID.cameraDisabled,
            action: wrappedActions.onToggleCamera
        )
    }

    var participantsControl: MeetingRoomBottomBarControl? {
        guard state.showParticipantList else { return nil }

        return MeetingRoomBottomBarControl(
            id: "participants",
            label: "Participants",
            image: VERACommonUIAsset.Images.group2Solid.swiftUIImage,
            isActive: showParticipantsList,
            action: wrappedActions.onToggleParticipants
        )
    }

    var layoutControl: MeetingRoomBottomBarControl {
        MeetingRoomBottomBarControl(
            id: "layout",
            label: "Layout",
            image: state.layout == .grid
                ? VERACommonUIAsset.Images.appsSolid.swiftUIImage
                : VERACommonUIAsset.Images.layout2Solid.swiftUIImage,
            isActive: true,
            action: wrappedActions.onToggleLayout
        )
    }

    var endCallControl: MeetingRoomBottomBarControl {
        MeetingRoomBottomBarControl(
            id: "end-call",
            label: "End call",
            image: Image(systemName: "phone.down.fill"),
            isActive: true,
            accessibilityIdentifier: MeetingRoomAccessibilityID.endCallButton,
            action: wrappedActions.onEndCall
        )
    }

    private var wrappedActions: MeetingRoomActions {
        MeetingRoomActions(
            onShare: { url in
                onBottomBarInteraction()
                actions.onShare(url)
            },
            onRetry: {
                onBottomBarInteraction()
                actions.onRetry()
            },
            onToggleMic: {
                onBottomBarInteraction()
                actions.onToggleMic()
            },
            onToggleCamera: {
                onBottomBarInteraction()
                actions.onToggleCamera()
            },
            onCameraSwitch: {
                onBottomBarInteraction()
                actions.onCameraSwitch()
            },
            onEndCall: {
                onBottomBarInteraction()
                actions.onEndCall()
            },
            onToggleParticipants: {
                onBottomBarInteraction()
                showParticipantsList.toggle()
            },
            onToggleLayout: {
                onBottomBarInteraction()
                actions.onToggleLayout()
            }
        )
    }
}

#Preview {
    MeetingRoomView(
        state: .init(
            roomName: "heart-of-gold",
            roomURL: .init(string: "http://example.com"),
            isMicEnabled: true,
            isCameraEnabled: true,
            participants: [],
            layout: .activeSpeaker,
            activeSpeakerId: nil,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            showParticipantList: true,
            callState: .connected,
            archivingState: .archiving(""),
            noiseSuppressionState: .disabled
        ),
        actions: .init())
}
