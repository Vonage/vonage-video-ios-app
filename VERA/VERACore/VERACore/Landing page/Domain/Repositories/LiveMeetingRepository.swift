//
//  Created by Vonage on 9/7/25.
//

import Foundation

public protocol LiveMeetingRepository {
    func observeRoom(_ roomName: String) -> AsyncStream<LiveMeeting>
}
