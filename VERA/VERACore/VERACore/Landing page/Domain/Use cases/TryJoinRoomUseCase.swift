//
//  Created by Vonage on 7/8/25.
//

import Foundation

// User will enter in existing room
public final class TryJoinRoomUseCase {

    public enum Error: Swift.Error {
        case invalidRoomName
    }

    public init() {
    }

    public func callAsFunction(_ name: String) throws {

        if !name.isValidRoomName {
            throw Error.invalidRoomName
        }
    }
}
