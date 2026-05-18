//
//  Created by Vonage on 14/7/25.
//

import SwiftUI
import VERACommonUI

struct JoinRoomButton: View {

    let onJoinRoom: () -> Void

    var body: some View {
        FilledButton(
            text: Text("Join meeting", bundle: .veraCore),
            onAction: onJoinRoom
        )
        .accessibilityIdentifier(WaitingRoomAccessibilityID.joinMeetingButton)
    }
}

#Preview {
    JoinRoomButton {}
}
