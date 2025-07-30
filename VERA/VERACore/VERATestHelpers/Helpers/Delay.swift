//
//  Created by Vonage on 18/7/25.
//

import Foundation

// 0.01 seconds delay
public func delay(nanoseconds duration: UInt64 = 10_000_000) async {
    try? await Task.sleep(nanoseconds: duration)
}
