//
//  Created by Vonage on 7/8/25.
//

import Foundation

public protocol TryCreatingANewRoomUseCase {
    func callAsFunction() -> String
}

// User will create a new room
public final class DefaultTryCreatingANewRoomUseCase: TryCreatingANewRoomUseCase {

    private let roomNameGenerator: RoomNameGenerator

    public init(roomNameGenerator: RoomNameGenerator) {
        self.roomNameGenerator = roomNameGenerator
    }

    public func callAsFunction() -> String {
        return roomNameGenerator.generate()
    }
}
