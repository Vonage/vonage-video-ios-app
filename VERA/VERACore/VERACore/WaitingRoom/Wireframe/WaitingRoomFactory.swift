//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

public class WaitingRoomFactory {

    public init() {}

    public func make(
        roomName: RoomName,
        onNavigateToRoom: @escaping (RoomName) -> Void
    ) -> some View {
        WaitingRoomScreen(
            viewModel: .init(roomName: roomName),
            onNavigateToRoom: onNavigateToRoom
        )
    }
}
