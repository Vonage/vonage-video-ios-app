//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomSDKAction tests")
struct MeetingRoomSDKActionTests {

    @Test("callDidEnd action is creatable")
    func callDidEndAction() {
        let action = MeetingRoomSDKAction.callDidEnd
        if case .callDidEnd = action {
            // pass
        } else {
            Issue.record("Expected callDidEnd action")
        }
    }

    @Test("goBack action carries room name")
    func goBackAction() {
        let action = MeetingRoomSDKAction.goBack("test-room")
        if case .goBack(let name) = action {
            #expect(name == "test-room")
        } else {
            Issue.record("Expected goBack action")
        }
    }
}
