//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

public struct MeetingRoomView: View {

    private let state: MeetingRoomState
    private let actions: MeetingRoomActions

    @State private var isBottomBarVisible = true
    @State private var isNavigationBarVisible = true
    @State private var showParticipantsList = false
    @State private var hideTimer: Timer?

    public init(
        state: MeetingRoomState,
        actions: MeetingRoomActions
    ) {
        self.state = state
        self.actions = actions
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
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isNavigationBarVisible)
                .contentShape(Rectangle())
                .onTapGesture {
                    showBottomBarAndResetTimer()
                }

                VStack(alignment: .center) {
                    Spacer()
                    BottomBar(
                        isMicEnabled: state.isMicEnabled,
                        isCameraEnabled: state.isCameraEnabled,
                        participantsCount: state.participantsCount,
                        unreadMessagesCount: state.unreadMessagesCount,
                        showChatButton: state.showChatButton,
                        allowMicrophoneControl: state.allowMicrophoneControl,
                        allowCameraControl: state.allowCameraControl,
                        showParticipantList: state.showParticipantList,
                        currentLayout: state.layout,
                        actions: wrappedActions
                    )
                    .opacity(isBottomBarVisible ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isBottomBarVisible)
                    .onTapGesture {
                        showBottomBarAndResetTimer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .onAppear {
                startHideTimer()
            }
            .onDisappear {
                cancelHideTimer()
            }
            #if !os(macOS)
                .toolbar(isNavigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .if(iOS26Available()) { view in
                    view
                    .modifier(iOS26ToolbarModifier())
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
                        let isIosAppOnMac = ProcessInfo.processInfo.isiOSAppOnMac
                        if !isIosAppOnMac && state.allowCameraControl {
                            Button {
                                onBottomBarInteraction()
                                actions.onCameraSwitch()
                            } label: {
                                VERACommonUIAsset.Images.cameraSwitchLine.swiftUIImage
                            }.disabled(!state.isCameraEnabled)
                        }
                        if state.allowMicrophoneControl {
                            Button {
                                onBottomBarInteraction()
                                actions.onToggleMic()
                            } label: {
                                VERACommonUIAsset.Images.audioMidLine.swiftUIImage
                            }
                        }
                        if let roomURL = state.roomURL {
                            ShareLink(item: roomURL) {
                                VERACommonUIAsset.Images.shareLine.swiftUIImage
                            }
                        }
                    }
                }.tint(.white)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct iOS26ToolbarModifier: ViewModifier {
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

    private func startHideTimer() {
        cancelHideTimer()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                isBottomBarVisible = false
                isNavigationBarVisible = false
            }
        }
    }

    private func cancelHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    private func showBottomBarAndResetTimer() {
        cancelHideTimer()
        withAnimation(.easeInOut(duration: 0.4)) {
            isBottomBarVisible = true
            isNavigationBarVisible = true
        }
        startHideTimer()
    }

    private func onBottomBarInteraction() {
        showBottomBarAndResetTimer()
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
            },
            onShowChat: {
                onBottomBarInteraction()
                actions.onShowChat()
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
            showChatButton: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            showParticipantList: true,
            callState: .connected),
        actions: .init())
}
