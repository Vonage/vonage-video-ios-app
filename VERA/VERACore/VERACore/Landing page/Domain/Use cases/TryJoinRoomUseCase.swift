//
//  Created by Vonage on 7/8/25.
//

import Foundation

// User will enter in existing room
public final class TryJoinRoomUseCase {
        
    public enum Error: Swift.Error {
        case invalidRoomName
    }
    
    public func invoke(_ name: String) async throws {
        
        if (!name.isValidRoomName) {
            throw Error.invalidRoomName
        }
    }
}
