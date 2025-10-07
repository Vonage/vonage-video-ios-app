//
//  Created by Vonage on 19/9/25.
//

import Foundation

func assertMainThread() {
    assert(Thread.isMainThread, "This method must be called from the main thread")
}
