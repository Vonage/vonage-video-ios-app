//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct WaitingRoomView: View {

    private let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }

    public var body: some View {
        Text(roomName)
            .navigationTitle("Waiting room")
    }
}

#Preview {
    WaitingRoomView(roomName: "Room name")
}
