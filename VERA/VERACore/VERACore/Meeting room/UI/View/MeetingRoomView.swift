//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct MeetingRoomView: View {

    private let state: MeetingRoomState
    private let actions: MeetingRoomActions

    public init(
        state: MeetingRoomState,
        actions: MeetingRoomActions
    ) {
        self.state = state
        self.actions = actions
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MeetingRoomContent(
                    participants: state.participants,
                    showBottomSheet: false,
                    layout: state.layout,
                    activeSpeakerId: state.activeSpeakerId
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                BottomBar(
                    isMicEnabled: state.isMicEnabled,
                    isCameraEnabled: state.isCameraEnabled,
                    participantsCount: state.participantsCount,
                    actions: actions)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .navigationTitle(state.roomName)
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)

                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            actions.onEndCall()
                        } label: {
                            Image(systemName: "arrow.left")
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            actions.onCameraSwitch()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                        }
                        Button {
                            actions.onToggleMic()
                        } label: {
                            Image(systemName: "speaker.wave.2")
                        }
                        Button {
                            actions.onShare(state.roomName)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(.white)
    }
}

#Preview {
    MeetingRoomView(
        state: .init(
            roomName: "heart-of-gold",
            isMicEnabled: true,
            isCameraEnabled: true,
            participants: [],
            layout: .activeSpeaker,
            activeSpeakerId: nil),
        actions: .init())
}
