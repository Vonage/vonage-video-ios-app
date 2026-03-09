//
//  Created by Vonage on 7/8/25.
//

import Foundation
import VERADomain

extension RoomName {
    public var maxRoomNameLength: Int { 60 }

    public var isValidRoomName: Bool {
        guard count <= maxRoomNameLength else {
            return false
        }

        let regex = /^[a-z0-9_+\-]+$/
        return self.wholeMatch(of: regex) != nil
    }
}
