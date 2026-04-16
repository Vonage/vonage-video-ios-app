//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing
import VERADomain

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomSDKAction tests")
struct MeetingRoomSDKActionTests {

    @Test("navigateToGoodbye action is creatable")
    func navigateToGoodbyeAction() {
        let action = MeetingRoomSDKAction.navigateToGoodbye
        if case .navigateToGoodbye = action {
            // pass
        } else {
            Issue.record("Expected navigateToGoodbye action")
        }
    }

    @Test("navigateToWaitingRoom action carries room name")
    func navigateToWaitingRoomAction() {
        let action = MeetingRoomSDKAction.navigateToWaitingRoom("test-room")
        if case .navigateToWaitingRoom(let name) = action {
            #expect(name == "test-room")
        } else {
            Issue.record("Expected navigateToWaitingRoom action")
        }
    }

    @Test("presentAlert action carries alert item")
    func presentAlertAction() {
        let alertItem = AlertItem(
            title: "Test",
            message: "Test message"
        )
        let action = MeetingRoomSDKAction.presentAlert(alertItem)
        if case .presentAlert(let item) = action {
            #expect(item.title == "Test")
            #expect(item.message == "Test message")
        } else {
            Issue.record("Expected presentAlert action")
        }
    }

    @Test("navigateToSettings action is creatable")
    func navigateToSettingsAction() {
        let action = MeetingRoomSDKAction.navigateToSettings
        if case .navigateToSettings = action {
            // pass
        } else {
            Issue.record("Expected navigateToSettings action")
        }
    }
}
