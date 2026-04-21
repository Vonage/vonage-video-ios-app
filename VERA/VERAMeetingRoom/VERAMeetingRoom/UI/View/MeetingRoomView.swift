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
    private let state: MeetingRoomState
    private let actions: MeetingRoomActions
    @Binding private var extraButtons: [BottomBarButton]
    @Binding private var extraTopTrailingButtons: [ViewGenerator]

    @State private var isBottomBarVisible = true
    @State private var isNavigationBarVisible = true
    @State private var showParticipantsList = false
    @State private var urlToShare: URL?

    public init(
        state: MeetingRoomState,
        actions: MeetingRoomActions,
        extraButtons: Binding<[BottomBarButton]> = .constant([]),
        extraTopTrailingButtons: Binding<[ViewGenerator]> = .constant([])
    ) {
        self.state = state
        self.actions = actions
        self._extraButtons = extraButtons
        self._extraTopTrailingButtons = extraTopTrailingButtons
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeetingRoomContent(
                    participants: state.participants,
                    showBottomSheet: false,
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
                    BottomBar(
                        isMicEnabled: state.isMicEnabled,
                        isCameraEnabled: state.isCameraEnabled,
                        participantsCount: state.participantsCount,
                        allowMicrophoneControl: state.allowMicrophoneControl,
                        allowCameraControl: state.allowCameraControl,
                        showParticipantList: state.showParticipantList,
                        currentLayout: state.layout,
                        actions: wrappedActions,
                        extraButtons: _extraButtons
                    )
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
                }.tint(.white)
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
                .foregroundStyle(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
                .pulsating(
                    pulseFraction: MeetingRoomViewConstants.recordingPulseFraction,
                    durationSeconds: MeetingRoomViewConstants.recordingPulseDuration
                )
        }
    }

    private var noiseSuppressionIndicator: some View {
        VERACommonUIAsset.Images.noiseSuppressionEnabled.swiftUIImage
            .foregroundStyle(
                VERACommonUIAsset.SemanticColors.onAccent.swiftUIColor)
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
