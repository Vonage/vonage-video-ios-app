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
    }
}

#Preview {
    MeetingRoomView(state: .default, actions: .init())
}
