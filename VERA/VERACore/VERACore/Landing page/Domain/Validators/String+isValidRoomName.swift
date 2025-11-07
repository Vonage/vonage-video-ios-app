//
//  Created by Vonage on 7/8/25.
//

import Foundation

extension String {
    public var isValidRoomName: Bool {
        let regex = /^[a-z0-9_+\-]+$/
        return self.wholeMatch(of: regex) != nil
    }
}
