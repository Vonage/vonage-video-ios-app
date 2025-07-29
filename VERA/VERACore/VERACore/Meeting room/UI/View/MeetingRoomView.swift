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
        VStack {
            MeetingRoomContent(
                participants: state.participants,
                showBottomSheet: false
            )
            Spacer()
            BottomBar(
                isMicEnabled: state.isMicEnabled,
                isCameraEnabled: state.isCameraEnabled,
                participantsCount: state.participantsCount,
                actions: actions)
            .background(.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.85))
    }
}

#Preview {
    MeetingRoomView(state: .default, actions: .init())
}
