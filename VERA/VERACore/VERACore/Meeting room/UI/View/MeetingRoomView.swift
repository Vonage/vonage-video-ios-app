//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct MeetingRoomView: View {

    private let state: MeetingRoomState

    public init(state: MeetingRoomState) {
        self.state = state
    }

    public var body: some View {
        VStack {
            MeetingRoomContent(
                participants: state.participants,
                showBottomSheet: false
            )
            Spacer()
            BottomBar(isMicEnabled: true, isCameraEnabled: false, participantsCount: 25, actions: .init())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.85))
    }
}

#Preview {
    MeetingRoomView(state: .default)
}
