//
//  Created by Vonage on 1/7/26.
//

import Testing
import VERACommonUI
import VERADomain
import VERAMeetingRoom

@Suite("MeetingRoomNavigation tests")
struct MeetingRoomNavigationTests {

    @Test
    func presentForceMuteConfirmationDispatchesAlert() throws {
        var presentedAlert: AlertItem?
        var didConfirm = false
        let sut = MeetingRoomNavigation(
            actionHandler: { action in
                if case .presentAlert(let alert) = action {
                    presentedAlert = alert
                }
            },
            roomName: "heart-of-gold"
        )

        sut.presentForceMuteConfirmation(
            message: "Mute Arthur for everyone in the call? Only Arthur can unmute themselves.",
            confirmTitle: "Mute",
            cancelTitle: "Cancel"
        ) {
            didConfirm = true
        }

        let alert = try #require(presentedAlert)
        #expect(alert.title == "Mute Arthur for everyone in the call? Only Arthur can unmute themselves.")
        #expect(alert.message == "")
        #expect(alert.okAction == "Mute")
        #expect(alert.cancelAction == "Cancel")

        alert.onConfirm?()

        #expect(didConfirm)
    }
}
