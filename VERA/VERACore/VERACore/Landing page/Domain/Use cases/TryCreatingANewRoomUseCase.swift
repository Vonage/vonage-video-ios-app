//
//  Created by Vonage on 7/8/25.
//

import Foundation

// User will create a new room
public final class TryCreatingANewRoomUseCase {
    
    private let roomNameGenerator: RoomNameGenerator
    
    public init(roomNameGenerator: RoomNameGenerator) {
        self.roomNameGenerator = roomNameGenerator
    }

    public func invoke(_ name: String) throws {

        
    }
}
