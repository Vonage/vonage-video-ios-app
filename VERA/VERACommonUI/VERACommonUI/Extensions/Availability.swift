//
//  Created by Vonage on 11/9/25.
//

import Foundation

public func iOS26Available() -> Bool {
    if #available(iOS 26.0, *) {
        return true
    } else {
        return false
    }
}

public func iOS18Available() -> Bool {
    if #available(iOS 18.0, *) {
        return true
    } else {
        return false
    }
}
