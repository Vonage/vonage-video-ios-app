//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing
import VERADomain

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

    @Test("Navigation actions can be returned from detached tasks")
    func actionsAcrossTasks() async {
        let ended = await Task.detached { MeetingRoomSDKAction.callDidEnd }.value
        let back = await Task.detached { MeetingRoomSDKAction.goBack("test-room") }.value

        if case .callDidEnd = ended {
            // pass
        } else {
            Issue.record("Expected callDidEnd after transfer")
        }

        if case .goBack(let name) = back {
            #expect(name == "test-room")
        } else {
            Issue.record("Expected goBack after transfer")
        }
    }
}
