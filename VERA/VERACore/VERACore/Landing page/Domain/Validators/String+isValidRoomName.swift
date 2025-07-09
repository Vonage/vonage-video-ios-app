//
//  Created by Vonage on 7/8/25.
//

import Foundation

extension String {
    public var isValidRoomName: Bool {
        if #available(iOS 16.0, *) {
            let regex = /^[a-z0-9_+\-]+$/
            return self.wholeMatch(of: regex) != nil
        } else {
            // Fallback for iOS < 16
            let regex = "^[a-z0-9_+\\-]+$"
            return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
        }
    }
}
