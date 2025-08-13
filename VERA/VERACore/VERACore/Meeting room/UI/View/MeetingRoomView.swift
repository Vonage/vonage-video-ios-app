//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct MeetingRoomView: View {

    private let state: MeetingRoomState
    private let actions: MeetingRoomActions

    @State private var isBottomBarVisible = true
    @State private var isNavigationBarVisible = true
    @State private var hideTimer: Timer?

    public init(
        state: MeetingRoomState,
        actions: MeetingRoomActions
    ) {
        self.state = state
        self.actions = actions
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                MeetingRoomContent(
                    participants: state.participants,
                    showBottomSheet: false,
                    layout: state.layout,
                    activeSpeakerId: state.activeSpeakerId
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: isNavigationBarVisible ? 0 : -22)
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

            .onAppear {
                startHideTimer()
            }
            .onDisappear {
                cancelHideTimer()
            }
            #if !os(macOS)
                .toolbar(isNavigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            onBottomBarInteraction()
                            actions.onEndCall()
                        } label: {
                            Image(systemName: "arrow.left")
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            onBottomBarInteraction()
                            actions.onCameraSwitch()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                        }
                        Button {
                            onBottomBarInteraction()
                            actions.onToggleMic()
                        } label: {
                            Image(systemName: "speaker.wave.2")
                        }
                        if let roomURL = state.roomURL {
                            ShareLink(item: roomURL) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .onTapGesture {
                                onBottomBarInteraction()
                            }
                        }
                    }
                }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(.white)
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
                actions.onToggleParticipants()
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
            activeSpeakerId: nil),
        actions: .init())
}
