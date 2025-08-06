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
        NavigationView {
            ZStack {
                MeetingRoomContent(
                    participants: state.participants,
                    showBottomSheet: false
                )
                VStack {
                    Spacer()
                    BottomBar(
                        isMicEnabled: state.isMicEnabled,
                        isCameraEnabled: state.isCameraEnabled,
                        participantsCount: state.participantsCount,
                        actions: actions)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .navigationTitle(state.roomName)
            .navigationBarTitleDisplayMode(.inline)
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
                        actions.onToggleCamera()
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
        }
    }
}

#Preview {
    MeetingRoomView(state: .default, actions: .init())
}
