//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct RoomJoinContainer: View {
    let onHandleNewRoom: () -> Void
    let onJoinRoom: (String) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Start a new video meeting", bundle: .veraCore)
                .adaptiveFont(.heading4)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)

            NewRoomButton(onHandleNewRoom: onHandleNewRoom)

            JoinContainerSeparator()

            JoinExistingRoom(onJoinRoom: onJoinRoom)
        }
    }
}

#Preview {
    RoomJoinContainer(onHandleNewRoom: {}, onJoinRoom: { _ in })
}
