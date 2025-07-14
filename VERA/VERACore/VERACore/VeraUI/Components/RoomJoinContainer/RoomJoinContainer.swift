//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct RoomJoinContainer: View {
    let onHandleNewRoom: () -> Void
    let onJoinRoom: (String) -> Void

    var body: some View {
        VStack(alignment: .center) {
            NewRoomButton(onHandleNewRoom: onHandleNewRoom)

            JoinContainerSeparator()

            JoinExistingRoom(onJoinRoom: onJoinRoom)
        }.frame(maxWidth: 320)
    }
}

#Preview {
    RoomJoinContainer(onHandleNewRoom: {}, onJoinRoom: { _ in })
}
