//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

struct JoinRoomButton: View {

    let onJoinRoom: () -> Void

    var body: some View {
        Button {
            onJoinRoom()
        } label: {
            Text("Join")
        }
        .buttonStyle(NewRoomButtonStyle())
    }
}

#Preview {
    JoinRoomButton {}
}
