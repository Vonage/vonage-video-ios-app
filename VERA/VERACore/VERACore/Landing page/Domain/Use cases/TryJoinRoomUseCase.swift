//
//  Created by Vonage on 7/8/25.
//

import Foundation

// User will enter in existing room
public final class TryJoinRoomUseCase {
    
    private let roomNameValidator: RoomNameValidator
    
    public enum Error: Swift.Error {
        case invalidRoomName
    }
    
    public init(roomNameValidator: RoomNameValidator) {
        self.roomNameValidator = roomNameValidator
    }
    
    public func invoke(_ name: String) async throws {
        
        // Validate room name
        let isValid = roomNameValidator.isValid(name)
        
        if (!isValid) {
            throw Error.invalidRoomName
        }
    }
}
