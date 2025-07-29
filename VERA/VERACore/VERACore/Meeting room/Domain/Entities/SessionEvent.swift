//
//  Created by Vonage on 28/7/25.
//

import Foundation

public enum SessionEvent {
    case idle
    case connected
    case disconnected
    case streamReceived(streamId: String)
    case streamDropped(streamId: String)
    case error(_ error: Swift.Error)
}
